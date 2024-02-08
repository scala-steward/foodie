package services.recipe

import db.{ IngredientId, RecipeId }

case class IngredientUpdate(
    recipeId: RecipeId,
    id: IngredientId,
    amountUnit: AmountUnit
)

object IngredientUpdate {

  def update(ingredient: Ingredient, ingredientUpdate: IngredientUpdate): Ingredient =
    ingredient.copy(
      amountUnit = ingredientUpdate.amountUnit
    )

}
