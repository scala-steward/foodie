package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import spire.implicits._

@JsonCodec
case class Stats(
    nutrients: Seq[NutrientInformation]
)

object Stats {

  implicit val fromDomain: Transformer[services.stats.Stats, Stats] = { stats =>
    val dailyStats     = services.stats.Stats.dailyStats(stats)
    val totalNutrients = stats.dailyNutrients.qsum
    Stats(
      nutrients = dailyStats.map {
        case (nutrient, daily) =>
          NutrientInformation(
            name = nutrient.name,
            unit = nutrient.unit.transformInto[NutrientUnit],
            amounts = Amounts(
              total = totalNutrients.getOrElse(nutrient, 0),
              daily = daily.transformInto[Daily]
            )
          )
      }.toSeq
    )
  }

}
