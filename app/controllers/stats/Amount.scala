package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class Amount(
    value: BigDecimal,
    numberOfIngredients: Int,
    numberOfDefinedValues: Int
)
