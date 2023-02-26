package services.meal

import cats.data.OptionT
import db.daos.meal.MealKey
import db.generated.Tables
import db.{ MealEntryId, MealId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.RequestInterval
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: MealService.Companion
)(implicit
    executionContext: ExecutionContext
) extends MealService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]] =
    db.run(companion.allMeals(userId, interval))

  override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] = db.run(companion.getMeal(userId, id))

  // TODO: The error can be specialized, because the most likely case is that the user is missing,
  // and thus a foreign key constraint is not met.
  override def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]] =
    db.run(companion.createMeal(userId, UUID.randomUUID().transformInto[MealId], mealCreation))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Creation(error.getMessage).asServerError)
      }

  override def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]] =
    db.run(companion.updateMeal(userId, mealUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Update(error.getMessage).asServerError)
      }

  override def deleteMeal(userId: UserId, id: MealId): Future[Boolean] = db.run(companion.deleteMeal(userId, id))

  override def getMealEntries(userId: UserId, ids: Seq[MealId]): Future[Seq[MealEntry]] =
    db.run(companion.getMealEntries(userId, ids))

  override def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]] =
    db.run(companion.addMealEntry(userId, UUID.randomUUID().transformInto[MealEntryId], mealEntryCreation))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Entry.Creation(error.getMessage).asServerError)
      }

  override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]] =
    db.run(companion.updateMealEntry(userId, mealEntryUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Entry.Update(error.getMessage).asServerError)
      }

  override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean] =
    db.run(companion.removeMealEntry(userId, mealEntryId))
      .recover { _ => false }

}

object Live {

  class Companion @Inject() (
      mealDao: db.daos.meal.DAO,
      mealEntryDao: db.daos.mealEntry.DAO
  ) extends MealService.Companion {

    override def allMeals(
        userId: UserId,
        interval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[Meal]] =
      mealDao
        .allInInterval(userId, interval)
        .map(
          _.map(_.transformInto[Meal])
        )

    override def getMeal(
        userId: UserId,
        id: MealId
    )(implicit ec: ExecutionContext): DBIO[Option[Meal]] =
      OptionT(
        mealDao.find(MealKey(userId, id))
      ).map(_.transformInto[Meal]).value

    override def createMeal(
        userId: UserId,
        id: MealId,
        mealCreation: MealCreation
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val meal    = MealCreation.create(id, mealCreation)
      val mealRow = (meal, userId).transformInto[Tables.MealRow]
      mealDao
        .insert(mealRow)
        .map(_.transformInto[Meal])
    }

    override def updateMeal(
        userId: UserId,
        mealUpdate: MealUpdate
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val findAction = OptionT(getMeal(userId, mealUpdate.id))
        .getOrElseF(notFound)

      for {
        meal <- findAction
        _ <- mealDao.update(
          (
            MealUpdate
              .update(meal, mealUpdate),
            userId
          )
            .transformInto[Tables.MealRow]
        )
        updatedMeal <- findAction
      } yield updatedMeal
    }

    override def deleteMeal(
        userId: UserId,
        id: MealId
    )(implicit ec: ExecutionContext): DBIO[Boolean] =
      mealDao
        .delete(MealKey(userId, id))
        .map(_ > 0)

    override def getMealEntries(userId: UserId, ids: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Seq[MealEntry]] =
      for {
        matchingMeals <- mealDao.allOf(userId, ids)
        mealEntries <-
          mealEntryDao
            // TODO: Reconsider the conversion to and from mealId here, and in the DAO.
            .findAllFor(matchingMeals.map(_.id.transformInto[MealId]))
            .map(_.map(_.transformInto[MealEntry]))
      } yield mealEntries

    override def addMealEntry(
        userId: UserId,
        id: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val mealEntry    = MealEntryCreation.create(id, mealEntryCreation)
      val mealEntryRow = (mealEntry, mealEntryCreation.mealId).transformInto[Tables.MealEntryRow]
      ifMealExists(userId, mealEntryCreation.mealId) {
        mealEntryDao.insert(mealEntryRow).map(_.transformInto[MealEntry])
      }
    }

    override def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val findAction =
        OptionT(mealEntryDao.find(mealEntryUpdate.id)).getOrElseF(DBIO.failed(DBError.Meal.EntryNotFound))
      for {
        mealEntryRow <- findAction
        _ <- ifMealExists(userId, mealEntryRow.mealId.transformInto[MealId]) {
          mealEntryDao.update(
            (
              MealEntryUpdate
                .update(mealEntryRow.transformInto[MealEntry], mealEntryUpdate),
              mealEntryRow.mealId.transformInto[MealId]
            )
              .transformInto[Tables.MealEntryRow]
          )
        }
        updatedMealEntry <- findAction
      } yield updatedMealEntry.transformInto[MealEntry]
    }

    override def removeMealEntry(
        userId: UserId,
        id: MealEntryId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      OptionT(
        mealEntryDao.find(id)
      )
        .map(_.mealId)
        .semiflatMap(mealId =>
          ifMealExists(userId, mealId.transformInto[MealId]) {
            mealEntryDao
              .delete(id)
              .map(_ > 0)
          }
        )
        .getOrElse(false)

    private def ifMealExists[A](
        userId: UserId,
        id: MealId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      mealDao.exists(MealKey(userId, id)).flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.Meal.NotFound)

  }

}
