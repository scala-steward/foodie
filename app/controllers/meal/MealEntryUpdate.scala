package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class MealEntryUpdate(
    numberOfServings: BigDecimal
)

object MealEntryUpdate {

  implicit val toInternal: Transformer[MealEntryUpdate, services.meal.MealEntryUpdate] =
    Transformer
      .define[MealEntryUpdate, services.meal.MealEntryUpdate]
      .buildTransformer

}
