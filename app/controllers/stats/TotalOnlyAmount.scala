package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class TotalOnlyAmount(
    values: Option[BigDecimal],
    numberOfIngredients: Int,
    numberOfDefinedValues: Int
)
