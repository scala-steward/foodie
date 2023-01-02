package services.meal

import errors.{ ErrorContext, ServerError }
import cats.effect.unsafe.implicits._
import io.scalaland.chimney.dsl._
import services.{ MealEntryId, MealId, UserId }

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

  private lazy val mealEntriesMap: mutable.Map[(UserId, MealEntryId), MealEntry] =
    mutable.Map.from(
      fullMealsByUserId.flatMap {
        case (userId, fullMeals) =>
          fullMeals.flatMap { fullMeal =>
            fullMeal.mealEntries.map(mealEntry => (userId, mealEntry.id) -> mealEntry)
          }
      }
    )

  override def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]] =
    Future.successful(mealMap.collect { case ((uid, _), meal) if uid == userId => meal }.toSeq)

  override def getMeal(userId: UserId, id: MealId): Future[Option[Meal]] =
    Future.successful(mealMap.get((userId, id)))

  override def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]] =
    utils.random.RandomGenerator.randomUUID
      .map(id => Right(MealCreation.create(id.transformInto[MealId], mealCreation)))
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

  override def getMealEntries(userId: UserId, id: MealId): Future[Seq[MealEntry]] = ???

  override def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]] =
    ???

  override def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]] =
    ???

  override def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean] = ???
}

object MockMealService {}
