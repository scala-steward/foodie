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
      name = recipeUpdate.name,
      description = recipeUpdate.description,
      numberOfServings = recipeUpdate.numberOfServings,
      servingSize = recipeUpdate.servingSize
    )

}
