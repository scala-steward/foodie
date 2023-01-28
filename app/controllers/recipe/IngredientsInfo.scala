package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class IngredientsInfo(
    ingredients: Seq[Ingredient],
    weightInGrams: BigDecimal
)

object IngredientsInfo {

  implicit val fromInternal: Transformer[services.recipe.IngredientsInfo, IngredientsInfo] =
    Transformer
      .define[services.recipe.IngredientsInfo, IngredientsInfo]
      .buildTransformer

}
