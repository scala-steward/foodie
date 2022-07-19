package services.meal

import services.recipe.RecipeId

case class MealEntryUpdate(
    id: MealEntryId,
    recipeId: RecipeId,
    factor: BigDecimal
)
