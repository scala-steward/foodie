package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class IngredientUpdate(
    recipeId: UUID @@ RecipeId,
    ingredientId: UUID @@ IngredientId,
    amount: BigDecimal
)
