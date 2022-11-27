package services.stats

import services.{ FoodId, RecipeId }
import services.recipe.{ AmountUnit, IngredientCreation }

case class IngredientPreCreation(
    foodId: FoodId,
    amountUnit: AmountUnit
)

object IngredientPreCreation {

  def toCreation(recipeId: RecipeId, ingredientPreCreation: IngredientPreCreation): IngredientCreation =
    IngredientCreation(
      recipeId = recipeId,
      foodId = ingredientPreCreation.foodId,
      amountUnit = ingredientPreCreation.amountUnit
    )

}
