package action

import cats.data.EitherT
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl._
import play.api.libs.circe.Circe
import play.api.mvc.Results.BadRequest
import play.api.mvc._
import pureconfig.ConfigSource
import pureconfig.generic.auto._
import security.jwt.JwtConfiguration
import services.user.{ User, UserId, UserService }
import shapeless.tag.@@
import utils.jwt.JwtUtil

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class JwtAction @Inject() (
    override val parse: PlayBodyParsers,
    userService: UserService
)(implicit override val executionContext: ExecutionContext)
    extends ActionBuilder[Request, AnyContent]
    with Circe {

  private val jwtConfiguration = ConfigSource.default.loadOrThrow[JwtConfiguration]

  override def invokeBlock[A](
      request: Request[A],
      block: Request[A] => Future[Result]
  ): Future[Result] = {
    request.headers.get(RequestHeaders.userTokenHeader) match {
      case Some(token) =>
        val transformer = for {
          jwtContent <- EitherT.fromEither[Future](JwtUtil.validateJwt(token, jwtConfiguration.signaturePublicKey))
          user <- EitherT.fromOptionF[Future, ServerError, User](
            userService
              .get(
                jwtContent.userId.transformInto[UUID @@ UserId]
              ),
            ErrorContext.User.NotFound.asServerError
          )
          result <- {
            val resultWithExtraHeader =
              block(request)
                .map(_.withHeaders(RequestHeaders.userId -> user.id.toString))
            EitherT.liftF[Future, ServerError, Result](resultWithExtraHeader)
          }
        } yield result
        transformer.valueOr(error => BadRequest(error.asJson))
      case None =>
        Future.successful(
          BadRequest(ErrorContext.Authentication.Token.Missing.asServerError.asJson)
        )
    }
  }

  override val parser: BodyParser[AnyContent] = new BodyParsers.Default(parse)
}
