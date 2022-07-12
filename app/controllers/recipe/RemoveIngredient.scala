package controllers.recipe

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class RemoveIngredient(
    recipeId: UUID,
    ingredientId: Int
)
