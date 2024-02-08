package services.recipe

case class IngredientUpdate(
    amountUnit: AmountUnit
)

object IngredientUpdate {

  def update(ingredient: Ingredient, ingredientUpdate: IngredientUpdate): Ingredient =
    ingredient.copy(
      amountUnit = ingredientUpdate.amountUnit
    )

}
