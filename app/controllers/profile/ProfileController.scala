package controllers.profile

import action.UserAction
import cats.data.{ EitherT, OptionT }
import db.ProfileId
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.syntax._
import play.api.libs.circe.Circe
import play.api.mvc._
import services.DBError
import services.profile.ProfileService
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining.scalaUtilChainingOps

class ProfileController @Inject() (
    cc: ControllerComponents,
    profileService: ProfileService,
    userAction: UserAction
)(implicit executionContext: ExecutionContext)
    extends AbstractController(cc)
    with Circe {

  def all: Action[AnyContent] = userAction.async { request =>
    profileService
      .all(request.user.id)
      .map(
        _.pipe(
          _.map(_.transformInto[Profile])
        ).pipe(_.asJson)
          .pipe(Ok(_))
      )
      .recover(errorHandler)
  }

  def get(profileId: UUID): Action[AnyContent] = userAction.async { request =>
    OptionT(
      profileService
        .get(request.user.id, profileId.transformInto[ProfileId])
    ).fold(
      NotFound(ErrorContext.Profile.NotFound.asServerError.asJson): Result
    )(
      _.pipe(_.transformInto[Profile])
        .pipe(_.asJson)
        .pipe(Ok(_))
    ).recover(errorHandler)
  }

  def create: Action[ProfileCreation] = userAction.async(circe.tolerantJson[ProfileCreation]) { request =>
    EitherT(
      profileService
        .create(request.user.id, request.body.transformInto[services.profile.ProfileCreation])
    )
      .map(
        _.pipe(_.transformInto[Profile])
          .pipe(_.asJson)
          .pipe(Created(_))
      )
      .fold(badRequest, identity)
      .recover(errorHandler)
  }

  def update(profileId: UUID): Action[ProfileUpdate] = userAction.async(circe.tolerantJson[ProfileUpdate]) { request =>
    EitherT(
      profileService
        .update(
          request.user.id,
          profileId.transformInto[ProfileId],
          request.body.transformInto[services.profile.ProfileUpdate]
        )
    )
      .map(
        _.pipe(_.transformInto[Profile])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
      .fold(badRequest, identity)
      .recover(errorHandler)
  }

  def delete(profileId: UUID): Action[AnyContent] = userAction.async { request =>
    profileService
      .delete(request.user.id, profileId.transformInto[ProfileId])
      .map(
        _.pipe(_.asJson)
          .pipe(Ok(_))
      )
      .recover(errorHandler)
  }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

  private def errorHandler: PartialFunction[Throwable, Result] = { case error =>
    val context = error match {
      case DBError.Profile.NotFound =>
        ErrorContext.Profile.NotFound
    }

    BadRequest(context.asServerError.asJson)
  }

}
