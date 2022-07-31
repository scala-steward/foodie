package services.stats

import cats.data.NonEmptyList
import services.nutrient.{ Nutrient, NutrientMap }
import utils.{ MapUtil, MathUtil }
import spire.implicits._

case class Stats(
    dailyNutrients: Iterable[NutrientMap]
)

object Stats {

  def dailyStats(stats: Stats): Map[Nutrient, Daily] = {
    val dailyNutrients = stats.dailyNutrients
    val days           = dailyNutrients.size
    val average        = dailyNutrients.qsum.view.mapValues(_ / days).toMap
    val min            = dailyNutrients.foldLeft(NutrientMap.empty)((m1, m2) => MapUtil.unionWith(m1, m2)(_.min(_)))
    val max            = dailyNutrients.foldLeft(NutrientMap.empty)((m1, m2) => MapUtil.unionWith(m1, m2)(_.max(_)))
    val median = dailyNutrients
      .map(_.view.mapValues(NonEmptyList.of(_)).toMap)
      .foldLeft(Map.empty[Nutrient, NonEmptyList[BigDecimal]])((m1, m2) => MapUtil.unionWith(m1, m2)(_ ::: _))
      .view
      .mapValues(MathUtil.median[BigDecimal])
      .toMap

    average.map {
      case (nutrient, av) =>
        val daily = Daily(
          average = av,
          median = median.getOrElse(nutrient, 0),
          min = min.getOrElse(nutrient, 0),
          max = max.getOrElse(nutrient, 0)
        )
        nutrient -> daily
    }

  }

}
