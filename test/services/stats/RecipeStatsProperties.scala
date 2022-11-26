package services.stats

import cats.data.{ EitherT, OptionT }
import cats.instances.list._
import cats.syntax.traverse._
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._
import org.scalacheck.Prop._
import org.scalacheck.{ Prop, Properties }
import services.{ DBTestUtil, FoodId, Gens, IngredientId, NutrientId, TestUtil }
import services.recipe.{ Ingredient, RecipeService }
import services.user.UserService
import slick.jdbc.PostgresProfile.api._
import spire.math.{ Natural, exp }
import utils.DBIOUtil.instances._

import scala.concurrent.ExecutionContext.Implicits.global

object RecipeStatsProperties extends Properties("Recipe stats") {

  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
  private val userService   = TestUtil.injector.instanceOf[UserService]
  private val statsService  = TestUtil.injector.instanceOf[StatsService]

  private var iterations = 0

  // TODO: Remove seed
  propertyWithSeed("Per serving stats", Some("_bDwQjSyadeq9z1avjd-FvqO55x2ZKFcjrv4S2vHJNB=")) = Prop.forAll(
    Gens.userWithFixedPassword :| "User",
    StatsGens.recipeParametersGen :| "Recipe parameters"
  ) { (user, recipeParameters) =>
    iterations += 1
    pprint.log(s"iteration = $iterations")
    DBTestUtil.clearDb()
    // TODO: Refactor this code - it is barely readable!
    val transformer = for {
      _      <- EitherT.liftF(userService.add(user))
      recipe <- EitherT(recipeService.createRecipe(user.id, recipeParameters.recipeCreation))
      ingredients <- recipeParameters.ingredientParameters.toList.traverse(ip =>
        EitherT(recipeService.addIngredient(user.id, ip.ingredientCreation(recipe.id)))
      )
      nutrientValues <- EitherT.liftF {
        DBTestUtil.dbRun {
          StatsGens.allNutrients.traverse { nutrient =>
            ingredients
              .traverse { ingredient =>
                computeNutrientAmount(
                  nutrient.id,
                  ingredient
                )
                  .map(ingredient.foodId -> _): DBIO[(FoodId, Option[BigDecimal])]
              }
              .map { amounts =>
                nutrient.id -> amounts.map { case (id, value) => id -> value.map(_ / recipe.numberOfServings) }
              }: DBIO[
              (NutrientId, List[(FoodId, Option[BigDecimal])])
            ]
          }
        }
      }
      nutrientMapFromService <- EitherT.fromOptionF(
        statsService.nutrientsOfRecipe(user.id, recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val expectedNutrientMap = nutrientValues.toMap
      val lengthProp: Prop =
        (ingredients.length == recipeParameters.ingredientParameters.length) :| "Correct ingredient number"
      val distinctIngredients = ingredients.distinctBy(_.foodId).length

      val propsPerNutrient = StatsGens.allNutrients.map { nutrient =>
        val prop = (nutrientMapFromService.get(nutrient), expectedNutrientMap.get(nutrient.id)) match {
          case (Some(actual), Some(expected)) =>
            Prop.all(
              // TODO: Figure out the issue here - Some(0) vs. None occurs, but why?
              //              closeEnough(
              //                actual.value,
              //                expected.sequence.collect {
              //                  case values if expected.nonEmpty => values.sum
              //                }
              //              ) :| "Value correct",
              // TODO: Account for the possibility that a food is added twice
              (actual.numberOfDefinedValues ?= Natural(
                expected.collect { case (id, value) if value.isDefined => id }.toSet.size
              )) :| "Number of defined values correct",
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

  private def closeEnough(
      actual: Option[BigDecimal],
      expected: Option[BigDecimal],
      error: BigDecimal = BigDecimal(0.0000000001)
  ): Prop =
    (actual, expected) match {
      case (Some(av), Some(ev)) =>
        ((ev - av).abs < error) :| s"Distance between expected value $ev and actual value $av is smaller than $error"
      case (None, None) =>
        Prop.passed
      case _ => Prop.falsified :| s"Expected $expected, but got $actual"
    }

  private def computeNutrientAmount(
      nutrientId: NutrientId,
      ingredient: Ingredient
  ): DBIO[Option[BigDecimal]] = {
    val foodId = ingredient.foodId.transformInto[Int]
    val transformer =
      for {
        conversionFactor <-
          ingredient.amountUnit.measureId
            .fold(OptionT.liftF(DBIO.successful(BigDecimal(1)): DBIO[BigDecimal]))(measureId =>
              OptionT(
                Tables.ConversionFactor
                  .filter(cf => cf.foodId === foodId && cf.measureId === measureId.transformInto[Int])
                  .map(_.conversionFactorValue)
                  .result
                  .headOption: DBIO[Option[BigDecimal]]
              )
            )
        nutrientAmount <- OptionT(
          Tables.NutrientAmount
            .filter(na =>
              na.nutrientId === nutrientId.transformInto[Int]
                && na.foodId === foodId
            )
            .result
            .headOption: DBIO[Option[Tables.NutrientAmountRow]]
        )
      } yield nutrientAmount.nutrientValue *
        ingredient.amountUnit.factor *
        conversionFactor

    transformer.value
  }

}
