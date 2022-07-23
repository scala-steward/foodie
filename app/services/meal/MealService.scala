package services.meal

import db.generated.Tables
import errors.ServerError
import errors.ServerError.Or
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.user.UserId
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import spire.math.{ Above, All, Below, Bounded, Empty, Interval, Point }
import slick.jdbc.PostgresProfile.api._
import cats.syntax.traverse._
import spire.math.interval.{ EmptyBound, Unbound, ValueBound }
import utils.DBIOUtil.instances._
import cats.syntax.contravariantSemigroupal._
import cats.instances.function._
import utils.TransformerUtils.Implicits._

import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait MealService {
  def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]]
  def getMeal(userId: UserId, id: MealId): Future[Option[Meal]]

  def createMeal(userId: UserId, mealCreation: MealCreation): Future[Meal]
  def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]]
  def deleteMeal(userId: UserId, id: MealId): Future[Boolean]

  def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]]
  def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]]
  def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean]
}

object MealService {

  trait Companion {
    def allMeals(userId: UserId, interval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Seq[Meal]]
    def getMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Option[Meal]]

    def createMeal(userId: UserId, mealCreation: MealCreation)(implicit ec: ExecutionContext): DBIO[Meal]
    def updateMeal(userId: UserId, mealUpdate: MealUpdate)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Meal]]
    def deleteMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Boolean]

    def addMealEntry(
        userId: UserId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[ServerError.Or[MealEntry]]

    def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[ServerError.Or[MealEntry]]

    def removeMealEntry(userId: UserId, mealEntryId: MealEntryId)(implicit ec: ExecutionContext): DBIO[Boolean]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends MealService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]] =
      db.run(companion.allMeals(userId, interval))

    override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] = db.run(companion.getMeal(userId, id))

    override def createMeal(userId: UserId, mealCreation: MealCreation): Future[Meal] =
      db.run(companion.createMeal(userId, mealCreation))

    override def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[Or[Meal]] =
      db.run(companion.updateMeal(userId, mealUpdate))

    override def deleteMeal(userId: UserId, id: MealId): Future[Boolean] = db.run(companion.deleteMeal(userId, id))

    override def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[Or[MealEntry]] =
      db.run(companion.addMealEntry(userId, mealEntryCreation))

    override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[Or[MealEntry]] =
      db.run(companion.updateMealEntry(userId, mealEntryUpdate))

    override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean] =
      db.run(companion.removeMealEntry(userId, mealEntryId))

  }

  object Live extends Companion {

    override def allMeals(
        userId: UserId,
        interval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[Meal]] = {
      val startFilter: LocalDate => Rep[java.sql.Date] => Rep[Boolean] = start =>
        _ >= start.transformInto[java.sql.Date]

      val endFilter: LocalDate => Rep[java.sql.Date] => Rep[Boolean] = end => _ <= end.transformInto[java.sql.Date]

      val dateFilter: Rep[java.sql.Date] => Rep[Boolean] = (interval.from, interval.to) match {
        case (Some(start), Some(end)) => (startFilter(start), endFilter(end)).mapN(_ && _)
        case (Some(start), _)         => startFilter(start)
        case (_, Some(end))           => endFilter(end)
        case _                        => _ => true
      }

      Tables.Meal
        .filter(m => m.userId === userId.transformInto[UUID] && dateFilter(m.consumedOnDate))
        .map(_.id)
        .result
        .flatMap(
          _.traverse(id => getMeal(userId, id.transformInto[MealId]))
        )
        .map(_.flatten)
    }

    override def getMeal(
        userId: UserId,
        id: MealId
    )(implicit ec: ExecutionContext): DBIO[Option[Meal]] = ???

    override def createMeal(
        userId: UserId,
        mealCreation: MealCreation
    )(implicit ec: ExecutionContext): DBIO[Meal] = ???

    override def updateMeal(
        userId: UserId,
        mealUpdate: MealUpdate
    )(implicit ec: ExecutionContext): DBIO[Or[Meal]] = ???

    override def deleteMeal(
        userId: UserId,
        id: MealId
    )(implicit ec: ExecutionContext): DBIO[Boolean] = ???

    override def addMealEntry(
        userId: UserId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Or[MealEntry]] = ???

    override def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Or[MealEntry]] = ???

    override def removeMealEntry(
        userId: UserId,
        mealEntryId: MealEntryId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] = ???

  }

}
