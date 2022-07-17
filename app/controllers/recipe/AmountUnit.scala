package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID

@JsonCodec
case class AmountUnit(
    measureId: UUID,
    factor: BigDecimal
)

object AmountUnit {

  implicit val fromInternal: Transformer[services.recipe.AmountUnit, AmountUnit] =
    Transformer
      .define[services.recipe.AmountUnit, AmountUnit]
      .buildTransformer

  implicit val toInternal: Transformer[AmountUnit, services.recipe.AmountUnit] =
    Transformer
      .define[AmountUnit, services.recipe.AmountUnit]
      .buildTransformer

}
