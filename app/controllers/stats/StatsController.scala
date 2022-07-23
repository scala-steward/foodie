package controllers.stats

import action.JwtAction
import play.api.mvc.{ AbstractController, Action, ControllerComponents }

import javax.inject.Inject

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction
) extends AbstractController(controllerComponents) {

  def get: Action[StatsRequest] = ???
}
