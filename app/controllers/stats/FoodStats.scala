package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class FoodStats(
    nutrients: Seq[FoodNutrientInformation]
)

object FoodStats {

  implicit val fromDomain: Transformer[services.stats.NutrientAmountMap, FoodStats] = { nutrientMap =>
    val nutrients = nutrientMap.map {
      case (nutrient, amount) =>
        FoodNutrientInformation(
          base = nutrient.transformInto[NutrientInformationBase],
          amount = amount.value
        )
    }.toSeq
    FoodStats(
      nutrients = nutrients
    )
  }

}
