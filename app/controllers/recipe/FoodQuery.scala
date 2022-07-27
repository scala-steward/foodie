package controllers.recipe

import io.circe.generic.JsonCodec

@JsonCodec
case class FoodQuery(
    searchString: Option[String]
)
