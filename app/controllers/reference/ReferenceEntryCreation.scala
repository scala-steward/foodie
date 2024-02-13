package controllers.reference

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class ReferenceEntryCreation(
    nutrientCode: Int,
    amount: BigDecimal
)

object ReferenceEntryCreation {

  implicit val toInternal: Transformer[ReferenceEntryCreation, services.reference.ReferenceEntryCreation] =
    Transformer
      .define[ReferenceEntryCreation, services.reference.ReferenceEntryCreation]
      .buildTransformer

}
