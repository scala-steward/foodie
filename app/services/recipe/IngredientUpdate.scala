package services.recipe

case class IngredientUpdate(
    id: IngredientId,
    amountUnit: AmountUnit
)

object IngredientUpdate {

  def update(ingredient: Ingredient, ingredientUpdate: IngredientUpdate): Ingredient =
    ingredient.copy(
      amountUnit = ingredientUpdate.amountUnit
    )

}