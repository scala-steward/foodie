package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class Ingredient(
    id: UUID,
    foodId: Int,
    amountUnit: AmountUnit
)

object Ingredient {

  implicit val fromInternal: Transformer[services.recipe.Ingredient, Ingredient] =
    Transformer
      .define[services.recipe.Ingredient, Ingredient]
      .buildTransformer

}
