package services.recipe

import services.RecipeId

case class RecipeCreation(
    name: String,
    description: Option[String]
)

object RecipeCreation {

  def create(id: RecipeId, recipeCreation: RecipeCreation): RecipeInfo =
    RecipeInfo(
      id = id,
      name = recipeCreation.name,
      description = recipeCreation.description
    )

}
