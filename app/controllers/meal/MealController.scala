package controllers.meal

import action.JwtAction
import cats.data.{ EitherT, OptionT }
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.meal.{ DBError, MealEntryId, MealId, MealService }

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class MealController @Inject() (
    controllerComponents: ControllerComponents,
    mealService: MealService,
    jwtAction: JwtAction
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def all: Action[RequestInterval] =
    jwtAction.async(circe.tolerantJson[RequestInterval]) { request =>
      mealService
        .allMeals(request.user.id, RequestInterval.toInterval(request.body))
        .map(
          _.pipe(
            _.map(_.transformInto[Meal])
          )
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def get(id: UUID): Action[AnyContent] =
    jwtAction.async { request =>
      OptionT(mealService.getMeal(request.user.id, id.transformInto[MealId])).fold(
        NotFound: Result
      )(
        _.pipe(_.transformInto[Meal])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

  def create: Action[MealCreation] =
    jwtAction.async(circe.tolerantJson[MealCreation]) { request =>
      mealService
        .createMeal(request.user.id, request.body.transformInto[services.meal.MealCreation])
        .map(
          _.pipe(_.transformInto[Meal])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def update: Action[MealUpdate] =
    jwtAction.async(circe.tolerantJson[MealUpdate]) { request =>
      EitherT(
        mealService
          .updateMeal(request.user.id, request.body.transformInto[services.meal.MealUpdate])
      )
        .map(
          _.pipe(_.transformInto[Meal])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(notFoundHandler)
    }

  def delete(id: UUID): Action[AnyContent] =
    jwtAction.async { request =>
      mealService
        .deleteMeal(request.user.id, id.transformInto[MealId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def addMealEntry: Action[MealEntryCreation] =
    jwtAction.async(circe.tolerantJson[MealEntryCreation]) { request =>
      EitherT(
        mealService.addMealEntry(
          userId = request.user.id,
          mealEntryCreation = request.body.transformInto[services.meal.MealEntryCreation]
        )
      )
        .fold(
          badRequest,
          _ => Ok
        )
        .recover(notFoundHandler)
    }

  def updateMealEntry: Action[MealEntryUpdate] =
    jwtAction.async(circe.tolerantJson[MealEntryUpdate]) { request =>
      EitherT(
        mealService.updateMealEntry(
          userId = request.user.id,
          mealEntryUpdate = request.body.transformInto[services.meal.MealEntryUpdate]
        )
      )
        .fold(
          badRequest,
          _ => Ok
        )
        .recover(notFoundHandler)
    }

  def deleteMealEntry(id: UUID): Action[AnyContent] =
    jwtAction.async { request =>
      mealService
        .removeMealEntry(request.user.id, id.transformInto[MealEntryId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

  private def notFoundHandler: PartialFunction[Throwable, Result] = {
    case DBError.MealNotFound =>
      BadRequest(ErrorContext.Meal.NotFound.asServerError.asJson)
  }

}
