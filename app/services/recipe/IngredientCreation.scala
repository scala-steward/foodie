package services.recipe

import services.{ FoodId, IngredientId, RecipeId }

case class IngredientCreation(
    recipeId: RecipeId,
    foodId: FoodId,
    amountUnit: AmountUnit
)

object IngredientCreation {

  def create(id: IngredientId, ingredientCreation: IngredientCreation): Ingredient =
    Ingredient(
      id = id,
      foodId = ingredientCreation.foodId,
      amountUnit = ingredientCreation.amountUnit
    )

}
