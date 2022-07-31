package controllers.stats

import io.circe.generic.JsonCodec

@JsonCodec
case class Daily(
    average: BigDecimal,
    median: BigDecimal,
    min: BigDecimal,
    max: BigDecimal
)
