package services.stats

import services.recipe.RecipeCreation

case class RecipeParameters(
    recipeCreation: RecipeCreation,
    ingredientParameters: List[IngredientParameters]
)
