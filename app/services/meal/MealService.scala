package services.meal

import errors.ServerError
import errors.ServerError.Or
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.user.UserId
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import spire.math.Interval

import java.time.LocalDate
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait MealService {
  def allMeals(userId: UserId, interval: Interval[LocalDate]): Future[Seq[Meal]]
  def getMeal(userId: UserId, id: MealId): Future[Option[Meal]]

  def createMeal(userId: UserId, mealCreation: MealCreation): Future[Meal]
  def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]]
  def deleteMeal(userId: UserId, id: MealId): Future[Boolean]

  def addMealEntry(userId: UserId, mealId: MealId, addEntry: MealEntryCreation): Future[ServerError.Or[MealEntry]]
  def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]]
  def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean]
}

object MealService {

  trait Companion {
    def allMeals(userId: UserId, interval: Interval[LocalDate]): DBIO[Seq[Meal]]
    def getMeal(userId: UserId, id: MealId): DBIO[Option[Meal]]

    def createMeal(userId: UserId, mealCreation: MealCreation): DBIO[Meal]
    def updateMeal(userId: UserId, mealUpdate: MealUpdate): DBIO[ServerError.Or[Meal]]
    def deleteMeal(userId: UserId, id: MealId): DBIO[Boolean]

    def addMealEntry(userId: UserId, mealId: MealId, addEntry: MealEntryCreation): DBIO[ServerError.Or[MealEntry]]
    def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): DBIO[ServerError.Or[MealEntry]]
    def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): DBIO[Boolean]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends MealService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allMeals(userId: UserId, interval: Interval[LocalDate]): Future[Seq[Meal]] =
      db.run(companion.allMeals(userId, interval))

    override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] = db.run(companion.getMeal(userId, id))

    override def createMeal(userId: UserId, mealCreation: MealCreation): Future[Meal] =
      db.run(companion.createMeal(userId, mealCreation))

    override def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[Or[Meal]] =
      db.run(companion.updateMeal(userId, mealUpdate))

    override def deleteMeal(userId: UserId, id: MealId): Future[Boolean] = db.run(companion.deleteMeal(userId, id))

    override def addMealEntry(userId: UserId, mealId: MealId, addEntry: MealEntryCreation): Future[Or[MealEntry]] =
      db.run(companion.addMealEntry(userId, mealId, addEntry))

    override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[Or[MealEntry]] =
      db.run(companion.updateMealEntry(userId, mealEntryUpdate))

    override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean] =
      db.run(companion.removeMealEntry(userId, mealEntryId))

  }

  object Live extends Companion {
    override def allMeals(userId: UserId, interval: Interval[LocalDate]): DBIO[Seq[Meal]] = ???

    override def getMeal(userId: UserId, id: MealId): DBIO[Option[Meal]] = ???

    override def createMeal(userId: UserId, mealCreation: MealCreation): DBIO[Meal] = ???

    override def updateMeal(userId: UserId, mealUpdate: MealUpdate): DBIO[Or[Meal]] = ???

    override def deleteMeal(userId: UserId, id: MealId): DBIO[Boolean] = ???

    override def addMealEntry(userId: UserId, mealId: MealId, addEntry: MealEntryCreation): DBIO[Or[MealEntry]] = ???

    override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): DBIO[Or[MealEntry]] = ???

    override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): DBIO[Boolean] = ???
  }

}
