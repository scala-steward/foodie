package controllers.recipe

import play.api.mvc.{ Action, AnyContent, ControllerComponents }

import java.util.UUID
import javax.inject.Inject

class RecipeController @Inject() (controllerComponents: ControllerComponents)
    extends UserController(controllerComponents) {

  def get(id: UUID): Action[AnyContent]          = ???
  def create: Action[RecipeCreation]             = ???
  def update: Action[RecipeUpdate]               = ???
  def delete(id: UUID): Action[AnyContent]       = ???
  def addIngredient: Action[AddIngredient]       = ???
  def removeIngredient: Action[RemoveIngredient] = ???
  def updateAmount: Action[IngredientUpdate]     = ???

}
