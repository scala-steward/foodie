package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class PlainStats(
    nutrients: Seq[PlainNutrientInformation]
)

object PlainStats {

  implicit val fromDomain: Transformer[services.nutrient.NutrientMap, PlainStats] = { nutrientMap =>
    val nutrients = nutrientMap.map {
      case (nutrient, amount) =>
        PlainNutrientInformation(
          base = nutrient.transformInto[NutrientInformationBase],
          amount = amount.amount
        )
    }.toSeq
    PlainStats(
      nutrients = nutrients
    )
  }

}
