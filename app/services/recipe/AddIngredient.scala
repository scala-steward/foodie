package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class AddIngredient(
    recipeId: UUID @@ RecipeId,
    ingredientId: Int,
    amount: BigDecimal
)
