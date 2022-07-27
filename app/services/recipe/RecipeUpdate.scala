package services.recipe

import services.RecipeId

case class RecipeUpdate(
    id: RecipeId,
    name: String,
    description: Option[String]
)

object RecipeUpdate {

  def update(recipeInfo: RecipeInfo, recipeUpdate: RecipeUpdate): RecipeInfo =
    recipeInfo.copy(
      name = recipeUpdate.name,
      description = recipeUpdate.description
    )

}
