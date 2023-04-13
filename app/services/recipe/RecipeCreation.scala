package services.recipe

import db.RecipeId

case class RecipeCreation(
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal,
    servingSize: Option[String]
)

object RecipeCreation {

  def create(id: RecipeId, recipeCreation: RecipeCreation): Recipe =
    Recipe(
      id = id,
      name = recipeCreation.name.trim,
      description = recipeCreation.description.map(_.trim),
      numberOfServings = recipeCreation.numberOfServings,
      servingSize = recipeCreation.servingSize.map(_.trim)
    )

}
