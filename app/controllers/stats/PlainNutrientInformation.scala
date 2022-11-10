package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class PlainNutrientInformation(
    base: NutrientInformationBase,
    amount: BigDecimal
)
