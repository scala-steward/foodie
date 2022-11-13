package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class TotalOnlyAmount(
    value: Option[BigDecimal],
    numberOfIngredients: Int,
    numberOfDefinedValues: Int
)
