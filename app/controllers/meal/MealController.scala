package controllers.meal

import controllers.recipe.UserController
import play.api.mvc.{ Action, AnyContent, ControllerComponents }

import java.util.UUID
import javax.inject.Inject

class MealController @Inject() (controllerComponents: ControllerComponents)
    extends UserController(controllerComponents) {

  def get(id: UUID): Action[AnyContent]    = ???
  def all: Action[Meal]                    = ???
  def add: Action[MealCreation]            = ???
  def update: Action[MealUpdate]           = ???
  def delete(id: UUID): Action[AnyContent] = ???

}
