package services.recipe

import services.user.UserId
import shapeless.tag.@@

import java.util.UUID

case class IngredientUpdate(
    userId: UUID @@ UserId,
    recipeId: UUID @@ RecipeId,
    id: UUID @@ IngredientId,
    amountUnit: AmountUnit
)
