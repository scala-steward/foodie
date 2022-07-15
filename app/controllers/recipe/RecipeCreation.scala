package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class RecipeCreation(
    name: String,
    description: Option[String]
)

object RecipeCreation {

  implicit val toDB: Transformer[RecipeCreation, services.recipe.RecipeCreation] =
    Transformer
      .define[RecipeCreation, services.recipe.RecipeCreation]
      .buildTransformer

}
