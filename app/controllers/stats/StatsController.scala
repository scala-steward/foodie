package controllers.stats

import action.UserAction
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.nutrient.NutrientService
import services.stats.StatsService
import utils.TransformerUtils.Implicits._
import utils.date.Date

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.ExecutionContext
import scala.util.chaining.scalaUtilChainingOps

class StatsController @Inject() (
    controllerComponents: ControllerComponents,
    userAction: UserAction,
    statsService: StatsService,
    nutrientService: NutrientService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def get(from: Option[String], to: Option[String]): Action[AnyContent] =
    userAction.async { request =>
      statsService
        .nutrientsOverTime(
          userId = request.user.id,
          requestInterval = RequestInterval(
            from = from.flatMap(Date.parse),
            to = to.flatMap(Date.parse)
          ).transformInto[services.stats.RequestInterval]
        )
        .map(
          _.pipe(_.transformInto[Stats])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def ofFood(foodId: Int): Action[AnyContent] =
    userAction.async {
      statsService
        .nutrientsOfFood(foodId.transformInto[services.FoodId])
        .map(
          _.fold(NotFound: Result)(
            _.pipe(_.transformInto[FoodStats])
              .pipe(_.asJson)
              .pipe(Ok(_))
          )
        )
    }

  def ofComplexFood(recipeId: UUID): Action[AnyContent] =
    userAction.async { request =>
      statsService
        .nutrientsOfComplexFood(request.user.id, recipeId.transformInto[services.ComplexFoodId])
        .map(
          _.fold(NotFound: Result)(
            _.pipe(_.transformInto[ComplexFoodStats])
              .pipe(_.asJson)
              .pipe(Ok(_))
          )
        )
    }

  def ofRecipe(recipeId: UUID): Action[AnyContent] =
    userAction.async { request =>
      statsService
        .nutrientsOfRecipe(request.user.id, recipeId.transformInto[services.RecipeId])
        .map(
          _.fold(NotFound: Result)(
            _.pipe(_.transformInto[TotalOnlyStats])
              .pipe(_.asJson)
              .pipe(Ok(_))
          )
        )
    }

  def ofMeal(mealId: UUID): Action[AnyContent] =
    userAction.async { request =>
      statsService
        .nutrientsOfMeal(request.user.id, mealId.transformInto[services.MealId])
        .map(
          _.pipe(_.transformInto[TotalOnlyStats])
            .pipe(_.asJson)
            .pipe(Ok(_))
        )
    }

  def allNutrients: Action[AnyContent] =
    userAction.async {
      nutrientService.all.map(
        _.map(_.transformInto[Nutrient])
          .pipe(_.asJson)
          .pipe(Ok(_))
      )
    }

}
