package services.duplication.meal

import db.{ MealEntryId, MealId, UserId }
import errors.ServerError
import services.meal.{ Meal, MealEntry }
import slick.dbio.DBIO
import utils.date.SimpleDate

import scala.concurrent.{ ExecutionContext, Future }

trait Duplication {

  def duplicate(userId: UserId, id: MealId): Future[ServerError.Or[Meal]]

}

object Duplication {

  case class DuplicatedMealEntry(
      mealEntry: MealEntry,
      newId: MealEntryId
  )

  trait Companion {

    def duplicateMeal(
        userId: UserId,
        id: MealId,
        newId: MealId,
        timestamp: SimpleDate
    )(implicit ec: ExecutionContext): DBIO[Meal]

    def duplicateMealEntries(
        newMealId: MealId,
        mealEntries: Seq[DuplicatedMealEntry]
    )(implicit ec: ExecutionContext): DBIO[Seq[MealEntry]]

  }

}
