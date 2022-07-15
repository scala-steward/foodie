package services.recipe

import errors.ServerError
import shapeless.tag.@@

import java.util.UUID
import scala.concurrent.Future

trait RecipeService {

  def getRecipe(id: UUID @@ RecipeId): Future[Option[Recipe]]
  def createRecipe(recipeCreation: RecipeCreation): Future[Recipe]
  def updateRecipe(recipeUpdate: RecipeUpdate): Future[Recipe]
  def deleteRecipe(id: UUID @@ RecipeId): Future[ServerError.Or[Unit]]

  def addIngredient(addIngredient: AddIngredient): Future[ServerError.Or[Unit]]
  def removeIngredient(ingredientId: UUID @@ IngredientId): Future[ServerError.Or[Unit]]
  def updateAmount(ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Unit]]
}
