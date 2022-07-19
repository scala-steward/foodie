package services.recipe

case class IngredientUpdate(
    recipeId: RecipeId,
    id: IngredientId,
    amountUnit: AmountUnit
)
