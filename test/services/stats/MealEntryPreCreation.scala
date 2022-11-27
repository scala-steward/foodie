package services.stats

import services.meal.MealEntryCreation
import services.{ MealId, RecipeId }

case class MealEntryPreCreation(
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntryPreCreation {

  def toCreation(mealId: MealId, mealEntryPreCreation: MealEntryPreCreation): MealEntryCreation =
    MealEntryCreation(
      mealId = mealId,
      recipeId = mealEntryPreCreation.recipeId,
      numberOfServings = mealEntryPreCreation.numberOfServings
    )

}
