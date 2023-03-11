package controllers.stats

import controllers.meal.Meal
import controllers.recipe.Recipe
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class RecipeOccurrence(
    recipe: Recipe,
    lastUsedInMeal: Option[Meal]
)

object RecipeOccurrence {

  implicit val fromDomain: Transformer[services.stats.RecipeOccurrence, RecipeOccurrence] =
    Transformer
      .define[services.stats.RecipeOccurrence, RecipeOccurrence]
      .buildTransformer

}
