package services.meal

import cats.syntax.order._
import io.scalaland.chimney.dsl._
import services.common.RequestInterval
import services.{ MealEntryId, MealId, UserId }
import slick.dbio.DBIO
import utils.date.Date

import scala.collection.mutable
import scala.concurrent.ExecutionContext

sealed trait MockMealService extends MealService.Companion {
  protected def fullMealsByUserId: Seq[(UserId, Seq[FullMeal])]

  private lazy val mealMap: mutable.Map[(UserId, MealId), Meal] =
    mutable.Map.from(
      fullMealsByUserId.flatMap {
        case (userId, fullMeals) =>
          fullMeals.map { fullMeal => (userId, fullMeal.meal.id) -> fullMeal.meal }
      }
    )

  private lazy val mealEntriesMap: mutable.Map[(UserId, MealId, MealEntryId), MealEntry] =
    mutable.Map.from(
      fullMealsByUserId.flatMap {
        case (userId, fullMeals) =>
          fullMeals.flatMap { fullMeal =>
            fullMeal.mealEntries.map(mealEntry => (userId, fullMeal.meal.id, mealEntry.id) -> mealEntry)
          }
      }
    )

  override def allMeals(userId: UserId, interval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Seq[Meal]] = {
    def dateComparison(date: Date): Boolean =
      (interval.from.map(_.transformInto[Date]), interval.to.map(_.transformInto[Date])) match {
        case (Some(earliest), Some(latest)) => date >= earliest && date <= latest
        case (Some(earliest), None)         => date >= earliest
        case (None, Some(latest))           => date <= latest
        case _                              => true
      }

    DBIO.successful(mealMap.collect {
      case ((uid, _), meal) if uid == userId && dateComparison(meal.date.date) => meal
    }.toSeq)
  }

  override def getMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Option[Meal]] =
    DBIO.successful(mealMap.get((userId, id)))

  override def createMeal(userId: UserId, mealId: MealId, mealCreation: MealCreation)(implicit
      ec: ExecutionContext
  ): DBIO[Meal] = {
    DBIO.successful {
      val meal = MealCreation.create(mealId, mealCreation)
      mealMap.update((userId, mealId), meal)
      meal
    }
  }

  override def updateMeal(userId: UserId, mealUpdate: MealUpdate)(implicit ec: ExecutionContext): DBIO[Meal] =
    mealMap
      .updateWith(
        (userId, mealUpdate.id)
      )(
        _.map(MealUpdate.update(_, mealUpdate))
      )
      .fold(DBIO.failed(new Throwable(s"Error updating meal with meal id: ${mealUpdate.id}")): DBIO[Meal])(
        DBIO.successful
      )

  override def deleteMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Boolean] =
    DBIO.successful {
      mealMap
        .remove((userId, id))
        .isDefined
    }

  override def getMealEntries(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Seq[MealEntry]] =
    DBIO.successful {
      mealEntriesMap.collect { case ((uid, mid, _), mealEntry) if userId == uid && mid == id => mealEntry }.toSeq
    }

  override def addMealEntry(userId: UserId, mealEntryId: MealEntryId, mealEntryCreation: MealEntryCreation)(implicit
      ec: ExecutionContext
  ): DBIO[MealEntry] = {
    DBIO.successful {
      val mealEntry = MealEntryCreation.create(mealEntryId, mealEntryCreation)
      mealEntriesMap.update((userId, mealEntryCreation.mealId, mealEntryId), mealEntry)
      mealEntry
    }
  }

  override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate)(implicit
      ec: ExecutionContext
  ): DBIO[MealEntry] = {
    val action =
      for {
        mealId <- mealEntriesMap.collectFirst {
          case ((uid, mealId, mealEntryId), _) if uid == userId && mealEntryId == mealEntryUpdate.id => mealId
        }
        mealEntry <-
          mealEntriesMap
            .updateWith(
              (userId, mealId, mealEntryUpdate.id)
            )(
              _.map(MealEntryUpdate.update(_, mealEntryUpdate))
            )
      } yield mealEntry

    action.fold(
      DBIO.failed(new Throwable(s"Error updating meal entry with id: ${mealEntryUpdate.id}")): DBIO[MealEntry]
    )(DBIO.successful)
  }

  override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId)(implicit ec: ExecutionContext): DBIO[Boolean] =
    DBIO.successful {
      val deletion = for {
        mealId <- mealEntriesMap.collectFirst {
          case ((uId, mealId, meId), _) if uId == userId && mealEntryId == meId => mealId
        }
        _ <- mealEntriesMap.remove((userId, mealId, mealEntryId))
      } yield ()
      deletion.isDefined
    }

}

object MockMealService {

  def fromCollection(fullMeals: Seq[(UserId, Seq[FullMeal])]): MealService.Companion =
    new MockMealService {
      override protected val fullMealsByUserId: Seq[(UserId, Seq[FullMeal])] = fullMeals
    }

}
