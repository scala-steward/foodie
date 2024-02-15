package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class ReferenceMapUpdate(
    name: String
)

object ReferenceMapUpdate {

  implicit val toInternal: Transformer[ReferenceMapUpdate, services.reference.ReferenceMapUpdate] =
    Transformer
      .define[ReferenceMapUpdate, services.reference.ReferenceMapUpdate]
      .buildTransformer

}
