package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

@JsonCodec
case class Measure(
    id: Int,
    name: String
)

object Measure {

  implicit val fromInternal: Transformer[services.recipe.Measure, Measure] =
    Transformer
      .define[services.recipe.Measure, Measure]
      .buildTransformer

}
