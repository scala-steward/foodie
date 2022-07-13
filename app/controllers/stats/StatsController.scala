package controllers.stats

import controllers.recipe.UserController
import play.api.mvc.{ Action, ControllerComponents }

import javax.inject.Inject

class StatsController @Inject() (controllerComponents: ControllerComponents)
    extends UserController(controllerComponents) {

  def get: Action[StatsRequest] = ???
}
