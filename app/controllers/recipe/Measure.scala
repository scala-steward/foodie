package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.IdUtils.Implicits._

@JsonCodec
case class Measure(
    id: Int,
    name: String
)

object Measure {

  implicit val toInternal: Transformer[Measure, services.recipe.Measure] =
    Transformer
      .define[Measure, services.recipe.Measure]
      .buildTransformer

}
