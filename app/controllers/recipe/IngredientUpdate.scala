package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class IngredientUpdate(
    amountUnit: AmountUnit
)

object IngredientUpdate {

  implicit val toInternal: Transformer[IngredientUpdate, services.recipe.IngredientUpdate] =
    Transformer
      .define[IngredientUpdate, services.recipe.IngredientUpdate]
      .buildTransformer

}
