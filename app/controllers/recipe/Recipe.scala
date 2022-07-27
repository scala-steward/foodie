package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class Recipe(
    recipeInfo: RecipeInfo,
    ingredients: Seq[Ingredient]
)

object Recipe {

  implicit val fromInternal: Transformer[services.recipe.Recipe, Recipe] =
    Transformer
      .define[services.recipe.Recipe, Recipe]
      .buildTransformer

}
