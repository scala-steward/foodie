package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class IngredientCreation(
    foodId: Int,
    amountUnit: AmountUnit
)

object IngredientCreation {

  implicit val toInternal: Transformer[IngredientCreation, services.recipe.IngredientCreation] =
    Transformer
      .define[IngredientCreation, services.recipe.IngredientCreation]
      .buildTransformer

}
