package controllers.stats

import action.UserAction
import cats.data.OptionT
import controllers.common.RequestInterval
import io.circe.syntax._
import io.scalaland.chimney.dsl.TransformerOps
import play.api.libs.circe.Circe
import play.api.mvc._
import services.common
import services.complex.food.ComplexFoodService
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
    complexFoodService: ComplexFoodService,
    nutrientService: NutrientService
)(implicit ec: ExecutionContext)
    extends AbstractController(controllerComponents)
    with Circe {

  def get(from: Option[String], to: Option[String]): Action[AnyContent] =
    userAction.async { request =>
      for {
        stats <-
          statsService
            .nutrientsOverTime(
              userId = request.user.id,
              requestInterval = RequestInterval(
                from = from.flatMap(Date.parse),
                to = to.flatMap(Date.parse)
              ).transformInto[common.RequestInterval]
            )
        weightInGrams <- statsService.weightOfMeals(request.user.id, stats.meals.map(_.id))
      } yield (stats, weightInGrams)
        .pipe(_.transformInto[Stats])
        .pipe(_.asJson)
        .pipe(Ok(_))
    }

  def ofFood(foodId: Int): Action[AnyContent] =
    userAction.async {
      statsService
        .nutrientsOfFood(foodId.transformInto[db.FoodId])
        .map(
          _.fold(NotFound: Result)(
            _.pipe(nutrients => (nutrients, BigDecimal(100)).transformInto[FoodStats])
              .pipe(_.asJson)
              .pipe(Ok(_))
          )
        )
    }

  def ofComplexFood(recipeId: UUID): Action[AnyContent] =
    userAction.async { request =>
      val typedRecipeId = recipeId.transformInto[db.ComplexFoodId]
      val transformer = for {
        nutrients   <- OptionT(statsService.nutrientsOfComplexFood(request.user.id, typedRecipeId))
        complexFood <- OptionT(complexFoodService.get(request.user.id, typedRecipeId))
      } yield (nutrients, complexFood.amountGrams)
        .pipe(_.transformInto[TotalOnlyStats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer.getOrElse(NotFound)
    }

  def ofRecipe(recipeId: UUID): Action[AnyContent] =
    userAction.async { request =>
      val typedRecipeId = recipeId.transformInto[db.RecipeId]
      val transformer = for {
        nutrients     <- OptionT(statsService.nutrientsOfRecipe(request.user.id, typedRecipeId))
        weightInGrams <- OptionT(statsService.weightOfRecipe(request.user.id, typedRecipeId))
      } yield (nutrients, weightInGrams)
        .pipe(_.transformInto[TotalOnlyStats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer.getOrElse(NotFound)
    }

  def ofMeal(mealId: UUID): Action[AnyContent] =
    userAction.async { request =>
      val typedMealId = mealId.transformInto[db.MealId]

      val transformer = for {
        nutrients     <- OptionT.liftF(statsService.nutrientsOfMeal(request.user.id, typedMealId))
        weightInGrams <- OptionT(statsService.weightOfMeal(request.user.id, typedMealId))
      } yield (nutrients, weightInGrams)
        .pipe(_.transformInto[TotalOnlyStats])
        .pipe(_.asJson)
        .pipe(Ok(_))

      transformer.getOrElse(NotFound)
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
