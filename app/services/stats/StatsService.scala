package services.stats

import db._
import services.common.RequestInterval
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait StatsService {

  def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats]

  def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountInformation]]
  def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId): Future[Option[NutrientAmountInformation]]
  def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountInformation]]

  def nutrientsOfMeal(userId: UserId, mealId: MealId): Future[NutrientAmountInformation]
}

object StatsService {

  trait Companion {
    def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Stats]

    def nutrientsOfFood(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[NutrientAmountInformation]]

    def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountInformation]]

    def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountInformation]]

    def nutrientsOfMeal(userId: UserId, mealId: MealId)(implicit ec: ExecutionContext): DBIO[NutrientAmountInformation]
  }

}
