package services.meal

import db.{ MealEntryId, MealId, UserId }
import errors.ServerError
import services.common.RequestInterval
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait MealService {
  def allMeals(userId: UserId, interval: RequestInterval): Future[Seq[Meal]]
  def getMeal(userId: UserId, id: MealId): Future[Option[Meal]]

  def createMeal(userId: UserId, mealCreation: MealCreation): Future[ServerError.Or[Meal]]
  def updateMeal(userId: UserId, mealUpdate: MealUpdate): Future[ServerError.Or[Meal]]
  def deleteMeal(userId: UserId, id: MealId): Future[Boolean]

  def getMealEntries(userId: UserId, ids: Seq[MealId]): Future[Map[MealId, Seq[MealEntry]]]
  def addMealEntry(userId: UserId, mealEntryCreation: MealEntryCreation): Future[ServerError.Or[MealEntry]]
  def updateMealEntry(userId: UserId, mealEntryUpdate: MealEntryUpdate): Future[ServerError.Or[MealEntry]]
  def removeMealEntry(userId: UserId, mealEntryId: MealEntryId): Future[Boolean]
}

object MealService {

  trait Companion {
    def allMeals(userId: UserId, interval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Seq[Meal]]
    def getMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Option[Meal]]

    def getMeals(userId: UserId, ids: Seq[MealId])(implicit ec: ExecutionContext): DBIO[Seq[Meal]]

    def createMeal(userId: UserId, id: MealId, mealCreation: MealCreation)(implicit ec: ExecutionContext): DBIO[Meal]
    def updateMeal(userId: UserId, mealUpdate: MealUpdate)(implicit ec: ExecutionContext): DBIO[Meal]
    def deleteMeal(userId: UserId, id: MealId)(implicit ec: ExecutionContext): DBIO[Boolean]

    def getMealEntries(userId: UserId, ids: Seq[MealId])(implicit
        ec: ExecutionContext
    ): DBIO[Map[MealId, Seq[MealEntry]]]

    def addMealEntry(
        userId: UserId,
        id: MealEntryId,
        mealEntryCreation: MealEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry]

    def updateMealEntry(
        userId: UserId,
        mealEntryUpdate: MealEntryUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[MealEntry]

    def removeMealEntry(
        userId: UserId,
        id: MealEntryId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

}
