package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class IngredientUpdate(
    recipeId: UUID @@ RecipeId,
    id: UUID @@ IngredientId,
    amountUnit: AmountUnit
)
