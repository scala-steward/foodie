package services.meal

import errors.{ ErrorContext, ServerError }
import cats.effect.unsafe.implicits._
import io.scalaland.chimney.dsl._
import services.{ MealEntryId, MealId, UserId }
import utils.TransformerUtils.Implicits._

import scala.collection.mutable
import scala.concurrent.Future

sealed trait MockMealService extends MealService {
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

  override def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]] =
    Future.successful(mealMap.collect { case ((uid, _), meal) if uid == userId => meal }.toSeq)

  override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] =
    Future.successful(mealMap.get((userId, id)))

  override def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]] =
    utils.random.RandomGenerator.randomUUID
      .map { id =>
        val mealId = id.transformInto[MealId]
        val meal   = MealCreation.create(mealId, mealCreation)
        mealMap.update((userId, mealId), meal)
        Right(meal)
      }
      .unsafeToFuture()

  override def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]] =
    Future.successful {
      mealMap
        .updateWith(
          (userId, mealUpdate.id)
        )(
          _.map(MealUpdate.update(_, mealUpdate))
        )
        .toRight(ErrorContext.Meal.Update(s"Unknown meal id: ${mealUpdate.id}").asServerError)
    }

  override def deleteMeal(userId: UserId, id: MealId): Future[Boolean] =
    Future.successful {
      mealMap
        .remove((userId, id))
        .isDefined
    }

  override def getMealEntries(userId: UserId, id: MealId): Future[Seq[MealEntry]] =
    Future.successful {
      mealEntriesMap.collect { case ((uid, mid, _), mealEntry) if userId == uid && mid == id => mealEntry }.toSeq
    }

  override def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]] =
    utils.random.RandomGenerator.randomUUID
      .map { id =>
        val mealEntryId = id.transformInto[MealEntryId]
        val mealEntry   = MealEntryCreation.create(mealEntryId, mealEntryCreation)
        mealEntriesMap.update((userId, mealEntryCreation.mealId, mealEntryId), mealEntry)
        Right(mealEntry)
      }
      .unsafeToFuture()

  override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]] =
    Future.successful {
      val update = for {
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

      update
        .toRight(ErrorContext.Meal.Update(s"Unknown meal entry id: ${mealEntryUpdate.id}").asServerError)
    }

  override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean] =
    Future.successful {
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

  def fromCollection(fullMeals: Seq[(UserId, Seq[FullMeal])]): MealService =
    new MockMealService {
      override protected val fullMealsByUserId: Seq[(UserId, Seq[FullMeal])] = fullMeals
    }

}
