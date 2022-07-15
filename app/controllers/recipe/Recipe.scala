package controllers.recipe

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class Recipe(
    id: UUID,
    ingredients: Seq[IngredientWithAmount]
)
