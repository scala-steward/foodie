package services.meal

import cats.data.OptionT
import db.daos.meal.MealKey
import db.daos.mealEntry.MealEntryKey
import db.generated.Tables
import db.{ MealEntryId, MealId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.syntax._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.RequestInterval
import services.common.Transactionally.syntax._
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
    db.runTransactionally(companion.allMeals(userId, interval))

  override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] =
    db.runTransactionally(companion.getMeal(userId, id))

  override def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]] =
    db.runTransactionally(companion.createMeal(userId, UUID.randomUUID().transformInto[MealId], mealCreation))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Creation(error.getMessage).asServerError)
      }

  override def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]] =
    db.runTransactionally(companion.updateMeal(userId, mealUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Update(error.getMessage).asServerError)
      }

  override def deleteMeal(userId: UserId, id: MealId): Future[Boolean] =
    db.runTransactionally(companion.deleteMeal(userId, id))

  override def getMealEntries(userId: UserId, ids: Seq[MealId]): Future[Map[MealKey, Seq[MealEntry]]] =
    db.runTransactionally(companion.getMealEntries(userId, ids))

  override def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]] =
    db.runTransactionally(
      companion.addMealEntry(userId, UUID.randomUUID().transformInto[MealEntryId], mealEntryCreation)
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Entry.Creation(error.getMessage).asServerError)
      }

  override def updateMealEntry(
      userId: UserId,
      mealEntryUpdate: MealEntryUpdate
  ): Future[ServerError.Or[MealEntry]] =
    db.runTransactionally(companion.updateMealEntry(userId, mealEntryUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Meal.Entry.Update(error.getMessage).asServerError)
      }

  override def removeMealEntry(userId: UserId, mealId: MealId, mealEntryId: MealEntryId): Future[Boolean] =
    db.runTransactionally(companion.removeMealEntry(userId, mealId, mealEntryId))
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

    override def getMeals(
        userId: UserId,
        ids: Seq[MealId]
    )(implicit ec: ExecutionContext): DBIO[Seq[Meal]] =
      mealDao
        .allOf(userId, ids)
        .map(_.map(_.transformInto[Meal]))

    override def createMeal(
        userId: UserId,
        id: MealId,
        mealCreation: MealCreation
    )(implicit ec: ExecutionContext): DBIO[Meal] = {
      val meal    = MealCreation.create(id, mealCreation)
      val mealRow = Meal.TransformableToDB(userId, meal).transformInto[Tables.MealRow]
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
          Meal
            .TransformableToDB(
              userId,
              MealUpdate.update(meal, mealUpdate)
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
    ): DBIO[Map[MealKey, Seq[MealEntry]]] =
      for {
        matchingMeals <- mealDao.allOf(userId, ids)
        mealEntries <-
          mealEntryDao
            .findAllFor(userId, matchingMeals.map(_.id.transformInto[MealId]))
            .map {
              _.view.mapValues(_.map(_.transformInto[MealEntry])).toMap
            }
      } yield mealEntries

    override def addMealEntry(
        userId: UserId,
        id: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val mealEntry = MealEntryCreation.create(id, mealEntryCreation)
      val mealEntryRow = MealEntry
        .TransformableToDB(userId, mealEntryCreation.mealId, mealEntry)
        .transformInto[Tables.MealEntryRow]
      mealEntryDao
        .insert(mealEntryRow)
        .map(_.transformInto[MealEntry])
    }

    override def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry] = {
      val findAction =
        OptionT(mealEntryDao.find(MealEntryKey(userId, mealEntryUpdate.mealId, mealEntryUpdate.id)))
          .getOrElseF(DBIO.failed(DBError.Meal.EntryNotFound))
      for {
        mealEntryRow <- findAction
        _ <- mealEntryDao.update(
          MealEntry
            .TransformableToDB(
              userId,
              mealEntryRow.mealId.transformInto[MealId],
              MealEntryUpdate.update(mealEntryRow.transformInto[MealEntry], mealEntryUpdate)
            )
            .transformInto[Tables.MealEntryRow]
        )
        updatedMealEntry <- findAction
      } yield updatedMealEntry.transformInto[MealEntry]
    }

    override def removeMealEntry(
        userId: UserId,
        mealId: MealId,
        id: MealEntryId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      mealEntryDao
        .delete(MealEntryKey(userId, mealId, id))
        .map(_ > 0)

  }

}
