package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.IdUtils.Implicits._

import java.util.UUID

@JsonCodec
case class Measure(
    id: UUID,
    name: String
)

object Measure {

  implicit val toInternal: Transformer[Measure, services.recipe.Measure] =
    Transformer
      .define[Measure, services.recipe.Measure]
      .buildTransformer

}
