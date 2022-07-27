package controllers.recipe

import action.JwtAction
import cats.data.{ EitherT, OptionT }
import errors.{ ErrorContext, ServerError }
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.recipe.{ DBError, RecipeService }
import services.{ FoodId, IngredientId, RecipeId }
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining._

class RecipeController @Inject() (
    controllerComponents: ControllerComponents,
    recipeService: RecipeService,
    jwtAction: JwtAction
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def getMeasures: Action[AnyContent] =
    jwtAction.async {
      recipeService.allMeasures
        .map(measuresResult)
    }

  def measuresFor(foodId: Int): Action[AnyContent] =
    jwtAction.async {
      recipeService
        .measuresFor(foodId.transformInto[FoodId])
        .map(measuresResult)
    }

  // TODO: Consider allowing specialized search instead of delivering all foods at once.
  def getFoods: Action[AnyContent] =
    jwtAction.async {
      recipeService.allFoods.map(
        _.map(_.transformInto[Food])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

  def getRecipes: Action[AnyContent] =
    jwtAction.async { request =>
      recipeService
        .allRecipes(request.user.id)
        .map(
          _.map(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def get(id: UUID): Action[AnyContent] =
    jwtAction.async { request =>
      OptionT(recipeService.getRecipe(request.user.id, id.transformInto[RecipeId])).fold(
        NotFound: Result
      )(
        _.pipe(_.transformInto[Recipe])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

  def create: Action[RecipeCreation] =
    jwtAction.async(circe.tolerantJson[RecipeCreation]) { request =>
      EitherT(
        recipeService
          .createRecipe(request.user.id, request.body.transformInto[services.recipe.RecipeCreation])
      )
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(recipeErrorHandler)
    }

  def update: Action[RecipeUpdate] =
    jwtAction.async(circe.tolerantJson[RecipeUpdate]) { request =>
      EitherT(
        recipeService
          .updateRecipe(request.user.id, request.body.transformInto[services.recipe.RecipeUpdate])
      )
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .fold(badRequest, identity)
        .recover(recipeErrorHandler)
    }

  def delete(id: UUID): Action[AnyContent] =
    jwtAction.async { request =>
      recipeService
        .deleteRecipe(request.user.id, id.transformInto[RecipeId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def addIngredient: Action[IngredientCreation] =
    jwtAction.async(circe.tolerantJson[IngredientCreation]) { request =>
      EitherT(
        recipeService.addIngredient(
          userId = request.user.id,
          ingredientCreation = request.body.transformInto[services.recipe.IngredientCreation]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[Ingredient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(recipeErrorHandler)
    }

  def removeIngredient(id: UUID): Action[AnyContent] =
    jwtAction.async { request =>
      recipeService
        .removeIngredient(request.user.id, id.transformInto[IngredientId])
        .map(
          _.pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def updateIngredient: Action[IngredientUpdate] =
    jwtAction.async(circe.tolerantJson[IngredientUpdate]) { request =>
      EitherT(
        recipeService.updateIngredient(
          userId = request.user.id,
          ingredientUpdate = request.body.transformInto[services.recipe.IngredientUpdate]
        )
      )
        .fold(
          badRequest,
          _.pipe(_.transformInto[Ingredient])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
        .recover(recipeErrorHandler)
    }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

  private def recipeErrorHandler: PartialFunction[Throwable, Result] = {
    case error =>
      val context = error match {
        case DBError.RecipeNotFound =>
          ErrorContext.Recipe.NotFound
        case DBError.RecipeIngredientNotFound =>
          ErrorContext.Recipe.Ingredient.NotFound
        case _ =>
          ErrorContext.Recipe.General(error.getMessage)
      }

      BadRequest(context.asServerError.asJson)
  }

  private def measuresResult(measures: Seq[services.recipe.Measure]): Result =
    measures
      .map(_.transformInto[Measure])
      .pipe(_.asJson)
      .pipe(Ok(_))

}
