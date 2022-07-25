package controllers.stats

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.time.LocalDate

@JsonCodec
case class RequestInterval(
    from: Option[LocalDate],
    to: Option[LocalDate]
)

object RequestInterval {

  implicit val toDomain: Transformer[RequestInterval, services.stats.RequestInterval] =
    Transformer
      .define[RequestInterval, services.stats.RequestInterval]
      .buildTransformer

}
