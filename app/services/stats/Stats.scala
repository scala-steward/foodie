package services.stats

import services.meal.Meal
import services.nutrient.NutrientMap

case class Stats(
    meals: Seq[Meal],
    nutrientMap: NutrientMap
)

object Stats {

  def dailyAverage(stats: Stats): NutrientMap = {
    val days = stats.meals
      .map(_.date.date)
      .distinct
      .size
    stats.nutrientMap.view
      .mapValues(_ / days)
      .toMap
  }

}
