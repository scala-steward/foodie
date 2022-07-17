package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class AmountUnit(
    measureId: Int,
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
