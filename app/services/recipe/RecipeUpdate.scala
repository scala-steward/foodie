package services.recipe

import services.RecipeId

case class RecipeUpdate(
    id: RecipeId,
    name: String,
    description: Option[String]
)

object RecipeUpdate {

  def update(recipe: Recipe, recipeUpdate: RecipeUpdate): Recipe =
    recipe.copy(
      name = recipeUpdate.name,
      description = recipeUpdate.description
    )

}
