package services.recipe

import services.{FoodId, RecipeId}

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
