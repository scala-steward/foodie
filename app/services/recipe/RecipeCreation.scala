package services.recipe

case class RecipeCreation(
    name: String,
    description: Option[String]
)

object RecipeCreation {

  def create(id: RecipeId, recipeCreation: RecipeCreation): Recipe =
    Recipe(
      id = id,
      name = recipeCreation.name,
      description = recipeCreation.description,
      ingredients = Seq.empty
    )

}
