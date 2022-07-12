package controllers.recipe

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class RecipeUpdate(
    id: UUID,
    name: String,
    description: Option[String]
)
