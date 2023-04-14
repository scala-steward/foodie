package services.recipe

import db.RecipeId

case class RecipeUpdate(
    id: RecipeId,
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal,
    servingSize: Option[String]
)

object RecipeUpdate {

  def update(recipe: Recipe, recipeUpdate: RecipeUpdate): Recipe =
    recipe.copy(
      name = recipeUpdate.name.trim,
      description = recipeUpdate.description.map(_.trim),
      numberOfServings = recipeUpdate.numberOfServings,
      servingSize = recipeUpdate.servingSize.map(_.trim)
    )

}
