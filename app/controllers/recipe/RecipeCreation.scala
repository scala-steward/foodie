package controllers.recipe

import io.circe.generic.JsonCodec

@JsonCodec
case class RecipeCreation(
    name: String,
    description: Option[String]
)
