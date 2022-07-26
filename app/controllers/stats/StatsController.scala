package controllers.stats

import action.JwtAction
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc.{ AbstractController, Action, ControllerComponents }
import services.stats.StatsService

import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining.scalaUtilChainingOps

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    jwtAction: JwtAction,
    statsService: StatsService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def get: Action[RequestInterval] =
    jwtAction.async(circe.tolerantJson[RequestInterval]) { request =>
      statsService
        .nutrientsOverTime(request.user.id, request.body.transformInto[services.stats.RequestInterval])
        .map(_.pipe(_.transformInto[Stats]).pipe(_.asJson).pipe(Ok(_)))
    }

}
