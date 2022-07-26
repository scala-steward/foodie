package controllers.stats

import controllers.meal.Meal
import io.circe.generic.JsonCodec

@JsonCodec
case class Stats(
    meals: Seq[Meal],
    nutrients: Seq[NutrientInformation]
)
