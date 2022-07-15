package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID

@JsonCodec
case class RecipeUpdate(
    id: UUID,
    name: String,
    description: Option[String]
)

object RecipeUpdate {

  implicit val toDB: Transformer[RecipeUpdate, services.recipe.RecipeUpdate] =
    Transformer
      .define[RecipeUpdate, services.recipe.RecipeUpdate]
      .buildTransformer

}
