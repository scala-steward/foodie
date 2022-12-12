package services.meal

import db.generated.Tables
import io.scalaland.chimney.dsl._
import services._
import slick.jdbc.PostgresProfile.api._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ServiceFunctions {

  def create(
      userId: UserId,
      meal: Meal
  ): Future[Unit] =
    createFull(
      userId,
      FullMeal(
        meal = meal,
        mealEntries = List.empty
      )
    )

  def createFull(
      userId: UserId,
      fullMeal: FullMeal
  ): Future[Unit] = {
    val action = for {
      _ <- Tables.Meal += (fullMeal.meal, userId).transformInto[Tables.MealRow]
      _ <- Tables.MealEntry ++= fullMeal.mealEntries.map(e => (e, fullMeal.meal.id).transformInto[Tables.MealEntryRow])

    } yield ()

    DBTestUtil.dbRun(action)
  }

  def createAll(
      userId: UserId,
      meals: List[Meal]
  ): Future[Unit] =
    createAllFull(
      userId,
      meals.map(FullMeal(_, List.empty))
    )

  def createAllFull(
      userId: UserId,
      fullMeals: List[FullMeal]
  ): Future[Unit] = {
    val action = for {
      _ <- Tables.Meal ++= fullMeals.map(fm => (fm.meal, userId).transformInto[Tables.MealRow])
      _ <-
        Tables.MealEntry ++= fullMeals
          .flatMap { fullMeal =>
            fullMeal.mealEntries
              .map(i => (i, fullMeal.meal.id).transformInto[Tables.MealEntryRow])
          }
    } yield ()

    DBTestUtil
      .dbRun(action)
  }

}
