package services.stats

import db._
import services.common.RequestInterval
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait StatsService {

  def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats]

  def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountMap]]
  def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId): Future[Option[NutrientAmountMap]]
  def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountMap]]

  def nutrientsOfMeal(userId: UserId, mealId: MealId): Future[NutrientAmountMap]

  def weightOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[BigDecimal]]
  def weightOfMeal(userId: UserId, mealId: MealId): Future[Option[BigDecimal]]

  def weightOfMeals(userId: UserId, mealIds: Seq[MealId]): Future[BigDecimal]
}

object StatsService {

  trait Companion {
    def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Stats]

    def nutrientsOfFood(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfMeal(userId: UserId, mealId: MealId)(implicit ec: ExecutionContext): DBIO[NutrientAmountMap]

    def weightOfRecipe(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[BigDecimal]]

    def weightOfMeal(userId: UserId, mealId: MealId)(implicit ec: ExecutionContext): DBIO[Option[BigDecimal]]

    def weightOfMeals(userId: UserId, mealIds: Seq[MealId])(implicit ec: ExecutionContext): DBIO[BigDecimal]
  }

}
