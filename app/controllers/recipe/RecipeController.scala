package controllers.recipe

import action.JwtAction
import play.api.mvc.{ AbstractController, Action, AnyContent, ControllerComponents }

import java.util.UUID
import javax.inject.Inject

class RecipeController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction
) extends AbstractController(controllerComponents) {

  def get(id: UUID): Action[AnyContent]          = ???
  def create: Action[RecipeCreation]             = ???
  def update: Action[RecipeUpdate]               = ???
  def delete(id: UUID): Action[AnyContent]       = ???
  def addIngredient: Action[AddIngredient]       = ???
  def removeIngredient: Action[RemoveIngredient] = ???
  def updateAmount: Action[IngredientUpdate]     = ???

}
