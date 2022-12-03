package services.recipe

import services.RecipeId

case class RecipePreUpdate(
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal
)

object RecipePreUpdate {

  def toUpdate(recipeId: RecipeId, recipePreUpdate: RecipePreUpdate): RecipeUpdate =
    RecipeUpdate(
      id = recipeId,
      name = recipePreUpdate.name,
      description = recipePreUpdate.description,
      numberOfServings = recipePreUpdate.numberOfServings
    )

}
