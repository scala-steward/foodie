package controllers.meal

import action.JwtAction
import play.api.mvc.{ AbstractController, Action, AnyContent, ControllerComponents }

import java.util.UUID
import javax.inject.Inject

class MealController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction
) extends AbstractController(controllerComponents) {

  def get(id: UUID): Action[AnyContent]    = ???
  def all: Action[Meal]                    = ???
  def add: Action[MealCreation]            = ???
  def update: Action[MealUpdate]           = ???
  def delete(id: UUID): Action[AnyContent] = ???

}
