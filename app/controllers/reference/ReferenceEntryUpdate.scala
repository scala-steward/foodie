package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class ReferenceEntryUpdate(
    amount: BigDecimal
)

object ReferenceEntryUpdate {

  implicit val toInternal: Transformer[ReferenceEntryUpdate, services.reference.ReferenceEntryUpdate] =
    Transformer
      .define[ReferenceEntryUpdate, services.reference.ReferenceEntryUpdate]
      .buildTransformer

}
