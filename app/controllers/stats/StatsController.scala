package controllers.stats

import action.JwtAction
import play.api.mvc.{ AbstractController, Action, ControllerComponents }
import services.stats.StatsService

import javax.inject.Inject

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction,
    statsService: StatsService
) extends AbstractController(controllerComponents) {

  def get: Action[StatsRequest] = ???
}
