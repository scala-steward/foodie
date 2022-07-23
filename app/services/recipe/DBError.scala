package services.recipe

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {
  case object RecipeNotFound           extends DBError("No recipe with the given id for the given user found")
  case object RecipeIngredientNotFound extends DBError("No recipe ingredient with the given id found")
}
