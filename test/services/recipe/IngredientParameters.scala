package services.recipe

import services.IngredientId

case class IngredientParameters(
    ingredientId: IngredientId,
    ingredientPreCreation: IngredientPreCreation
)
