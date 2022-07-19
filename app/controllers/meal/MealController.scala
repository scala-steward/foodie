package controllers.meal

import action.JwtAction
import play.api.mvc.{ AbstractController, Action, AnyContent, ControllerComponents }
import services.meal.MealService

import java.util.UUID
import javax.inject.Inject

class MealController @Inject() (
    controllerComponents: ControllerComponents,
    mealService: MealService,
    jwtAction: JwtAction
) extends AbstractController(controllerComponents) {

  def all: Action[AnyContent]           = ???
  def get(id: UUID): Action[AnyContent] = ???

  def create: Action[MealCreation]         = ???
  def update: Action[MealUpdate]           = ???
  def delete(id: UUID): Action[AnyContent] = ???

  def addMealEntry: Action[MealEntryCreation]       = ???
  def updateMealEntry: Action[MealEntryUpdate]      = ???
  def deleteMealEntry(id: UUID): Action[AnyContent] = ???
}
