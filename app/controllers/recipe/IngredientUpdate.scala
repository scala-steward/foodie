package controllers.recipe

import java.util.UUID

case class IngredientUpdate(
    recipeId: UUID,
    ingredientId: UUID,
    amount: BigDecimal
)
