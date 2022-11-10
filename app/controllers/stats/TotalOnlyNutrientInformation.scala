package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class TotalOnlyNutrientInformation(
    base: NutrientInformationBase,
    amount: TotalOnlyAmount
)
