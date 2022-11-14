package controllers.stats

import controllers.complex.ComplexFoodUnit
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class ComplexFoodStats(
    nutrients: Seq[FoodNutrientInformation],
    complexFoodUnit: ComplexFoodUnit
)

object ComplexFoodStats {

  implicit val fromDomain: Transformer[services.stats.ComplexFoodStats, ComplexFoodStats] = complexFoodStats =>
    ComplexFoodStats(
      nutrients = complexFoodStats.nutrientAmountMap.map(_.transformInto[FoodNutrientInformation]).toSeq,
      complexFoodUnit = complexFoodStats.unit.transformInto[ComplexFoodUnit]
    )

}
