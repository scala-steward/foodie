package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class Daily(
    average: BigDecimal,
    median: BigDecimal,
    min: BigDecimal,
    max: BigDecimal
)

object Daily {

  implicit val fromDomain: Transformer[services.stats.Daily, Daily] =
    Transformer
      .define[services.stats.Daily, Daily]
      .buildTransformer

}
