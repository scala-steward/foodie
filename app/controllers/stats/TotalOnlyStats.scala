package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class TotalOnlyStats(
    nutrients: Seq[TotalOnlyNutrientInformation],
    weightInGrams: BigDecimal
)

object TotalOnlyStats {

  implicit val fromDomain: Transformer[(services.stats.NutrientAmountMap, BigDecimal), TotalOnlyStats] = {
    case (nutrientAmountMap, weightInGrams) =>
      val nutrients = nutrientAmountMap.map {
        case (nutrient, amount) =>
          TotalOnlyNutrientInformation(
            nutrient.transformInto[NutrientInformationBase],
            amount = TotalOnlyAmount(
              value = amount.value,
              numberOfIngredients = amount.numberOfIngredients.intValue,
              numberOfDefinedValues = amount.numberOfDefinedValues.intValue
            )
          )
      }.toSeq
      TotalOnlyStats(
        nutrients = nutrients,
        weightInGrams = weightInGrams
      )
  }

}
