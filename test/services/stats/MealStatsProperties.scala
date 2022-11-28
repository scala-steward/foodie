package services.stats

import algebra.ring.AdditiveSemigroup
import cats.data.{ EitherT, NonEmptyList }
import cats.instances.list._
import cats.syntax.traverse._
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Prop, Properties, Test }
import services._
import services.meal.MealService
import services.recipe.RecipeService
import services.user.{ User, UserService }
import spire.implicits._
import spire.math.Natural
import utils.collection.MapUtil

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object MealStatsProperties extends Properties("Meal stats") {
  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
  private val mealService   = TestUtil.injector.instanceOf[MealService]
  private val userService   = TestUtil.injector.instanceOf[UserService]
  private val statsService  = TestUtil.injector.instanceOf[StatsService]

  private case class SetupPerMeal(
      user: User,
      recipes: Seq[RecipeParameters]
  )

  private val maxNumberOfRecipesPerMeal = Natural(10)

  private val setupPerMealGen = for {
    user    <- Gens.userWithFixedPassword
    recipes <- Gens.nonEmptyListOfAtMost(maxNumberOfRecipesPerMeal, StatsGens.recipeParametersGen)
  } yield SetupPerMeal(
    user = user,
    recipes = recipes.toList
  )

  propertyWithSeed("Per meal stats", Some("0qo71L0hNniSbfjhGP2pDhI2eih_Rg7p-FADLESTboB=")) = Prop.exists(
    setupPerMealGen :| "Per meal setup"
  ) { setup =>
    pprint.log("next iteration")
    DBTestUtil.clearDb()

    val preliminary = DBTestUtil.await(
      EitherT
        .liftF(userService.add(setup.user))
        .flatMap(_ =>
          setup.recipes
            .traverse {
              ServiceFunctions.createRecipe(recipeService)(setup.user, _)
            }
            .map {
              _.map(fr => fr.recipe.id -> fr).toMap
            }
        )
        .getOrRaise(new Throwable("Preliminary setup for meal generation failed")) // todo: Incorporate into property
    )
    Prop.forAll(StatsGens.mealGen(NonEmptyList.fromListUnsafe(preliminary.keys.toList))) { mealParameters =>
      val transformer = for {
        _ <- EitherT.liftF(userService.add(setup.user))
        recipeIngredients <-
          setup.recipes
            .traverse {
              ServiceFunctions.createRecipe(recipeService)(setup.user, _)
            }
            .map {
              _.map(fr => fr.recipe.id -> fr).toMap
            }
        fullMeal <- ServiceFunctions.createMeal(mealService)(setup.user, mealParameters)
        expectedNutrientValues <- EitherT.liftF[Future, ServerError, Map[NutrientId, Option[BigDecimal]]](
          mealParameters.mealEntryParameters
            .traverse { mep =>
              ServiceFunctions
                .computeNutrientAmounts(recipeIngredients(mep.mealEntryPreCreation.recipeId))
                .map(
                  _.view
                    .mapValues(_.map {
                      // TODO: Comparing the numbers of existing and non-existing values
                      //       is not directly possible in the current implementation
                      //       but would improve the test quality.
                      //       However, it may be tricky to find a good implementation
                      //       that is sufficiently different from the one already used
                      //       in the production code.
                      case (_, value) => value * mep.mealEntryPreCreation.numberOfServings
                    })
                    .toMap
                )
            }
            .map(
              _.foldLeft(Map.empty[NutrientId, Option[BigDecimal]])(
                MapUtil.unionWith(_, _)(AdditiveSemigroup[Option[BigDecimal]].plus)
              )
            )
        )
        nutrientMapFromService <- EitherT.liftF[Future, ServerError, NutrientAmountMap](
          statsService.nutrientsOfMeal(setup.user.id, fullMeal.meal.id)
        )
      } yield {
        val lengthProp: Prop =
          (fullMeal.mealEntries.length ?= mealParameters.mealEntryParameters.length) :| "Correct meal entry number"

        val propsPerNutrient = StatsGens.allNutrients.map { nutrient =>
          val prop = (nutrientMapFromService.get(nutrient), expectedNutrientValues.get(nutrient.id)) match {
            case (Some(actual), Some(expected)) =>
              Prop.all(
                PropUtil.closeEnough(actual.value, expected) :| "Value correct"
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

  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters = p.withMinSuccessfulTests(25)
}
