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
    val nutrients = nutrientMap.map(_.transformInto[FoodNutrientInformation]).toSeq
    FoodStats(
      nutrients = nutrients
    )
  }

}
