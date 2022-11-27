package services.stats

import services.RecipeId
import services.recipe.RecipeCreation

case class RecipeParameters(
    recipeId: RecipeId,
    recipeCreation: RecipeCreation,
    ingredientParameters: List[IngredientParameters]
)
