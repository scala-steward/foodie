package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class FoodInfo(
    id: Int,
    name: String
)

object FoodInfo {

  implicit val fromDomain: Transformer[services.recipe.FoodInfo, FoodInfo] =
    Transformer
      .define[services.recipe.FoodInfo, FoodInfo]
      .buildTransformer

}
