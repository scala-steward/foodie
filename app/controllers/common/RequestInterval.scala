package controllers.common

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import services.common
import utils.date.Date

@JsonCodec
case class RequestInterval(
    from: Option[Date],
    to: Option[Date]
)

object RequestInterval {

  implicit val toDomain: Transformer[RequestInterval, common.RequestInterval] =
    Transformer
      .define[RequestInterval, common.RequestInterval]
      .buildTransformer

}
