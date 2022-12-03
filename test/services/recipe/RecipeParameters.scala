package services.recipe

case class RecipeParameters(
    recipeCreation: RecipeCreation,
    ingredientParameters: List[IngredientParameters]
)
