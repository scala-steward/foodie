package services.stats

import cats.data.EitherT
import config.TestConfiguration
import errors.ErrorContext
import org.scalacheck.Prop._
import org.scalacheck.{ Prop, Properties, Test }
import services._
import services.recipe.RecipeService
import services.user.UserService
import spire.math.Natural

import scala.concurrent.ExecutionContext.Implicits.global

object RecipeStatsProperties extends Properties("Recipe stats") {

  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
  private val userService   = TestUtil.injector.instanceOf[UserService]
  private val statsService  = TestUtil.injector.instanceOf[StatsService]

  property("Per serving stats") = Prop.forAll(
    Gens.userWithFixedPassword :| "User",
    StatsGens.recipeParametersGen :| "Recipe parameters"
  ) { (user, recipeParameters) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _                      <- EitherT.liftF(userService.add(user))
      fullRecipe             <- ServiceFunctions.createRecipe(recipeService)(user, recipeParameters)
      expectedNutrientValues <- EitherT.liftF(ServiceFunctions.computeNutrientAmounts(fullRecipe))
      nutrientMapFromService <- EitherT.fromOptionF(
        statsService.nutrientsOfRecipe(user.id, fullRecipe.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val lengthProp: Prop =
        (fullRecipe.ingredients.length ?= recipeParameters.ingredientParameters.length) :| "Correct ingredient number"
      val distinctIngredients = fullRecipe.ingredients.distinctBy(_.foodId).length

      val propsPerNutrient = StatsGens.allNutrients.map { nutrient =>
        val prop = (nutrientMapFromService.get(nutrient), expectedNutrientValues.get(nutrient.id)) match {
          case (Some(actual), Some(expected)) =>
            val (expectedSize, expectedValue) = expected.fold((0, Option.empty[BigDecimal])) {
              case (size, value) => size -> Some(value)
            }
            Prop.all(
              PropUtil.closeEnough(actual.value, expectedValue) :| "Value correct",
              (actual.numberOfDefinedValues ?= Natural(expectedSize)) :| "Number of defined values correct",
              (actual.numberOfIngredients ?= Natural(distinctIngredients)) :| "Total number of ingredients matches"
            )
          case (None, None) => Prop.passed
          case _            => Prop.falsified
        }
        prop :| s"Correct values for nutrientId = ${nutrient.id}"
      }

      Prop.all(
        lengthProp +:
          propsPerNutrient: _*
      )
    }

    DBTestUtil.await(
      transformer.fold(
        error => {
          pprint.log(error.message)
          Prop.exception
        },
        identity
      )
    )
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests)

}
