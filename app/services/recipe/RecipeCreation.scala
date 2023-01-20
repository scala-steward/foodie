package services.recipe

import db.RecipeId

case class RecipeCreation(
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal
)

object RecipeCreation {

  def create(id: RecipeId, recipeCreation: RecipeCreation): Recipe =
    Recipe(
      id = id,
      name = recipeCreation.name,
      description = recipeCreation.description,
      numberOfServings = recipeCreation.numberOfServings
    )

}
