package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class Amount(
    amountUnits: List[AmountUnit]
)

object Amount {

  implicit val fromInternal: Transformer[services.recipe.Amount, Amount] =
    Transformer
      .define[services.recipe.Amount, Amount]
      .buildTransformer

  implicit val toInternal: Transformer[Amount, services.recipe.Amount] =
    Transformer
      .define[Amount, services.recipe.Amount]
      .buildTransformer

}
