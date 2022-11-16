package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class NutrientInformation(
    base: NutrientInformationBase,
    amounts: Amounts
)
