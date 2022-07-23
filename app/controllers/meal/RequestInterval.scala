package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.time.LocalDate

@JsonCodec
case class RequestInterval(
    from: Option[LocalDate],
    to: Option[LocalDate]
)

object RequestInterval {

  implicit val toDomain: Transformer[RequestInterval, services.meal.RequestInterval] =
    Transformer
      .define[RequestInterval, services.meal.RequestInterval]
      .buildTransformer

}
