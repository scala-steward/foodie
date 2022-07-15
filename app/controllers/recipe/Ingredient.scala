package controllers.recipe

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class Ingredient(
    id: UUID,
    name: String
)
