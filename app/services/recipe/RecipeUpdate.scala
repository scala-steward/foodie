package services.recipe

import db.RecipeId

case class RecipeUpdate(
    id: RecipeId,
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal
)

object RecipeUpdate {

  def update(recipe: Recipe, recipeUpdate: RecipeUpdate): Recipe =
    recipe.copy(
      name = recipeUpdate.name,
      description = recipeUpdate.description,
      numberOfServings = recipeUpdate.numberOfServings
    )

}
