package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import utils.date.SimpleDate

@JsonCodec
case class MealUpdate(
    date: SimpleDate,
    name: Option[String]
)

object MealUpdate {

  implicit val toDomain: Transformer[MealUpdate, services.meal.MealUpdate] =
    Transformer
      .define[MealUpdate, services.meal.MealUpdate]
      .buildTransformer

}
