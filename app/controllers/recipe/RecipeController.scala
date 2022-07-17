package controllers.recipe

import action.JwtAction
import cats.data.{ EitherT, OptionT }
import errors.ServerError
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.recipe.{ IngredientId, RecipeId, RecipeService }
import shapeless.tag.@@
import utils.IdUtils.Implicits._

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

  def getMeasures: Action[AnyContent] = ???

  // TODO: Consider allowing specialized search instead of delivering all foods at once.
  def getFoods: Action[AnyContent] = ???

  def get(id: UUID): Action[AnyContent] =
    jwtAction.async {
      OptionT(recipeService.getRecipe(id.transformInto[UUID @@ RecipeId])).fold(
        NotFound: Result
      )(
        _.pipe(_.transformInto[Recipe])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

  def create: Action[RecipeCreation] =
    jwtAction.async(circe.tolerantJson[RecipeCreation]) { request =>
      recipeService
        .createRecipe(request.body.transformInto[services.recipe.RecipeCreation])
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def update: Action[RecipeUpdate] =
    jwtAction.async(circe.tolerantJson[RecipeUpdate]) { request =>
      recipeService
        .updateRecipe(request.body.transformInto[services.recipe.RecipeUpdate])
        .map(
          _.pipe(_.transformInto[Recipe])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def delete(id: UUID): Action[AnyContent] =
    jwtAction.async {
      EitherT(recipeService.deleteRecipe(id.transformInto[UUID @@ RecipeId])).fold(
        badRequest,
        _ => Ok
      )
    }

  def addIngredient: Action[AddIngredient] =
    jwtAction.async(circe.tolerantJson[AddIngredient]) { request =>
      EitherT(recipeService.addIngredient(request.body.transformInto[services.recipe.AddIngredient])).fold(
        badRequest,
        _ => Ok
      )

    }

  def removeIngredient(id: UUID): Action[AnyContent] =
    jwtAction.async {
      EitherT(recipeService.removeIngredient(id.transformInto[UUID @@ IngredientId])).fold(
        badRequest,
        _ => Ok
      )
    }

  def updateAmount: Action[IngredientUpdate] =
    jwtAction.async(circe.tolerantJson[IngredientUpdate]) { request =>
      EitherT(recipeService.updateAmount(request.body.transformInto[services.recipe.IngredientUpdate])).fold(
        badRequest,
        _ => Ok
      )
    }

  private def badRequest(serverError: ServerError): Result =
    BadRequest(serverError.asJson)

}
