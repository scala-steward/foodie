package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class AddIngredient(
    recipeId: UUID @@ RecipeId,
    foodId: Int @@ FoodId,
    amountUnit: AmountUnit
)
