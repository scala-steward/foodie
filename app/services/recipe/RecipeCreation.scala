package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class RecipeCreation(
    name: String,
    description: Option[String]
)

object RecipeCreation {

  def create(id: UUID @@ RecipeId, recipeCreation: RecipeCreation): Recipe =
    Recipe(
      id = id,
      name = recipeCreation.name,
      description = recipeCreation.description,
      ingredients = Seq.empty
    )

}
