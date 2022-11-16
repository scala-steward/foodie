package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class FoodNutrientInformation(
    base: NutrientInformationBase,
    amount: Option[BigDecimal]
)

object FoodNutrientInformation {

  implicit val fromDomain: Transformer[(services.nutrient.Nutrient, services.stats.Amount), FoodNutrientInformation] = {
    case (nutrient, amount) =>
      FoodNutrientInformation(
        base = nutrient.transformInto[NutrientInformationBase],
        amount = amount.value
      )
  }

}
