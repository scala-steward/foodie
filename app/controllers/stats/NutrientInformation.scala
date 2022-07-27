package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class NutrientInformation(
    name: String,
    unit: NutrientUnit,
    amounts: Amounts
)
