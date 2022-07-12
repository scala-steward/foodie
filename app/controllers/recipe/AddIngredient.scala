package controllers.recipe

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class AddIngredient(
    recipeId: UUID,
    ingredientId: Int,
    amount: BigDecimal
)
