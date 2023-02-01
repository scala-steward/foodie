package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class RecipeUpdate(
    id: UUID,
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal,
    servingSize: Option[String]
)

object RecipeUpdate {

  implicit val toInternal: Transformer[RecipeUpdate, services.recipe.RecipeUpdate] =
    Transformer
      .define[RecipeUpdate, services.recipe.RecipeUpdate]
      .buildTransformer

}
