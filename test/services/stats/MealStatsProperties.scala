package services.stats

import algebra.ring.AdditiveSemigroup
import cats.data.{ EitherT, NonEmptyList }
import cats.instances.list._
import cats.syntax.contravariantSemigroupal._
import cats.syntax.traverse._
import config.TestConfiguration
import errors.ServerError
import io.scalaland.chimney.dsl.TransformerOps
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services._
import services.meal.{ Meal, MealService }
import services.recipe.RecipeService
import services.user.{ User, UserService }
import spire.compat._
import spire.implicits._
import spire.math.interval._
import spire.math.{ Interval, Natural }
import utils.collection.MapUtil
import utils.date.Date

import java.time.LocalDate
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object MealStatsProperties extends Properties("Meal stats") {
  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
  private val mealService   = TestUtil.injector.instanceOf[MealService]
  private val userService   = TestUtil.injector.instanceOf[UserService]
  private val statsService  = TestUtil.injector.instanceOf[StatsService]

  private case class SetupUserAndRecipes(
      user: User,
      recipes: Seq[RecipeParameters]
  )

  private val maxNumberOfRecipesPerMeal = Natural(10)

  private val setupUserAndRecipesGen = for {
    user    <- Gens.userWithFixedPassword
    recipes <- Gens.nonEmptyListOfAtMost(maxNumberOfRecipesPerMeal, StatsGens.recipeParametersGen)
  } yield SetupUserAndRecipes(
    user = user,
    recipes = recipes.toList
  )

  private def applyUserAndRecipeSetup(
      setup: SetupUserAndRecipes
  ): EitherT[Future, ServerError, Map[RecipeId, ServiceFunctions.FullRecipe]] =
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

  private def computeNutrientsPerMealEntry(fullRecipes: Map[RecipeId, ServiceFunctions.FullRecipe])(
      mealEntryParameters: MealEntryParameters
  ) = {
    ServiceFunctions
      .computeNutrientAmounts(fullRecipes(mealEntryParameters.mealEntryPreCreation.recipeId))
      .map(
        _.view
          .mapValues(
            _.map {
              // TODO: Comparing the numbers of existing and non-existing values
              //       is not directly possible in the current implementation
              //       but would improve the test quality.
              //       However, it may be tricky to find a good implementation
              //       that is sufficiently different from the one already used
              //       in the production code.
              case (_, value) => value * mealEntryParameters.mealEntryPreCreation.numberOfServings
            }
          )
          .toMap
      )
  }

  property("Per meal stats") = Prop.forAll(
    setupUserAndRecipesGen :| "Setup of user and recipes"
  ) { setup =>
    DBTestUtil.clearDb()

    DBTestUtil
      .await(applyUserAndRecipeSetup(setup).value)
      .fold(
        error => Prop.exception :| error.message,
        fullRecipes => {
          Prop.forAll(StatsGens.mealGen(NonEmptyList.fromListUnsafe(fullRecipes.keys.toList))) { mealParameters =>
            val transformer = for {
              fullMeal <- ServiceFunctions.createMeal(mealService)(setup.user, mealParameters)
              expectedNutrientValues <- EitherT.liftF[Future, ServerError, Map[NutrientId, Option[BigDecimal]]](
                mealParameters.mealEntryParameters
                  .traverse(computeNutrientsPerMealEntry(fullRecipes))
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
                val prop = PropUtil.closeEnough(
                  nutrientMapFromService.get(nutrient).flatMap(_.value),
                  expectedNutrientValues.get(nutrient.id).flatten
                )
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
      )

  }

  private case class OverTimeSetup(
      dateInterval: Interval[Date],
      mealParameters: Seq[MealParameters]
  )

  private def overTimeSetupGen(
      recipeIds: List[RecipeId],
      range: Natural = Natural(1000)
  ): Gen[OverTimeSetup] = {
    val latest         = range.intValue
    val earliest       = -latest
    val smallerDateGen = Gen.option(Gens.dateGen(earliest, latest))
    for {
      date1 <- smallerDateGen
      date2 <- smallerDateGen
      mealParameters <-
        NonEmptyList
          .fromList(recipeIds)
          .fold(Gen.const(List.empty[MealParameters]))(nel =>
            Gen.nonEmptyListOf(StatsGens.mealGen(nel, earliest, latest))
          )
    } yield {
      val dateInterval = (date1, date2) match {
        case (Some(d1), Some(d2)) =>
          if (d1 <= d2)
            Interval.closed(d1, d2)
          else Interval.closed(d2, d1)
        case (Some(d1), None) => Interval.atOrAbove(d1)
        case (None, Some(d2)) => Interval.atOrBelow(d2)
        case _                => Interval.all[Date]
      }

      OverTimeSetup(
        dateInterval = dateInterval,
        mealParameters = mealParameters
      )
    }
  }

  property("Over time stats") = Prop.forAll(
    setupUserAndRecipesGen :| "Setup of user and recipes"
  ) { setup =>
    DBTestUtil.clearDb()

    DBTestUtil
      .await(applyUserAndRecipeSetup(setup).value)
      .fold(
        error => Prop.exception :| error.message,
        fullRecipes => {
          Prop.forAll(overTimeSetupGen(fullRecipes.keys.toList)) { overTimeSetup =>
            val transformer = for {
              _ <- overTimeSetup.mealParameters.traverse(ServiceFunctions.createMeal(mealService)(setup.user, _))
              mealsInInterval =
                overTimeSetup.mealParameters
                  .filter(mp => overTimeSetup.dateInterval.contains(mp.mealCreation.date.date))
              expectedNutrientValues <- EitherT.liftF[Future, ServerError, Map[NutrientId, Option[BigDecimal]]](
                mealsInInterval
                  .flatMap(_.mealEntryParameters)
                  .traverse(computeNutrientsPerMealEntry(fullRecipes))
                  .map(
                    _.foldLeft(Map.empty[NutrientId, Option[BigDecimal]])(
                      MapUtil.unionWith(_, _)(AdditiveSemigroup[Option[BigDecimal]].plus)
                    )
                  )
              )
              statsFromService <- EitherT.liftF[Future, ServerError, Stats](
                statsService.nutrientsOverTime(
                  setup.user.id,
                  toRequestInterval(overTimeSetup.dateInterval)
                )
              )
            } yield {
              val mealsProp: Prop =
                compareMealAndParametersInOrder(statsFromService.meals, mealsInInterval) :| "Correct meals"

              val propsPerNutrient = StatsGens.allNutrients.map { nutrient =>
                val prop = PropUtil.closeEnough(
                  statsFromService.nutrientAmountMap.get(nutrient).flatMap(_.value),
                  expectedNutrientValues.get(nutrient.id).flatten
                )
                prop :| s"Correct values for nutrientId = ${nutrient.id}"
              }

              Prop.all(
                mealsProp +:
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
      )
  }

  // Regression test for a bug, where the meals were computed over all users.
  property("Meal stats restricted to user") = Prop.forAll(
    Gens.userWithFixedPassword :| "First user",
    Gens.userWithFixedPassword :| "Second user"
  ) { (user1, user2) =>
    DBTestUtil.clearDb()

    DBTestUtil
      .await(
        (
          applyUserAndRecipeSetup(SetupUserAndRecipes(user1, Seq.empty)),
          applyUserAndRecipeSetup(SetupUserAndRecipes(user2, Seq.empty))
        ).tupled.value
      )
      .fold(
        error => Prop.exception :| error.message,
        {
          case (_, _) =>
            Prop.forAll(
              overTimeSetupGen(List.empty) :| "Over time setup 1",
              overTimeSetupGen(List.empty) :| "Over time setup 2"
            ) {
              (overTimeSetup1, overTimeSetup2) =>
                val transformer =
                  for {
                    _ <- overTimeSetup1.mealParameters.traverse(ServiceFunctions.createMeal(mealService)(user1, _))
                    _ <- overTimeSetup2.mealParameters.traverse(ServiceFunctions.createMeal(mealService)(user2, _))
                    mealsInInterval =
                      overTimeSetup1.mealParameters
                        .filter(mp => overTimeSetup1.dateInterval.contains(mp.mealCreation.date.date))
                    statsFromService <- EitherT.liftF[Future, ServerError, Stats](
                      statsService.nutrientsOverTime(
                        user1.id,
                        toRequestInterval(overTimeSetup1.dateInterval)
                      )
                    )
                  } yield compareMealAndParametersInOrder(
                    statsFromService.meals,
                    mealsInInterval
                  )

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
      )
  }

  private def extractValue[A](bound: Bound[A]): Option[A] =
    bound match {
      case EmptyBound() => None
      case Unbound()    => None
      case Closed(x)    => Some(x)
      case Open(x)      => Some(x)
    }

  private def toRequestInterval(interval: Interval[Date]): RequestInterval = {
    def toLocalDate(bound: Bound[Date]) = extractValue(bound).map(_.transformInto[LocalDate])
    RequestInterval(
      from = toLocalDate(interval.lowerBound),
      to = toLocalDate(interval.upperBound)
    )
  }

  private def compareMealAndParametersInOrder(
      meals: Seq[Meal],
      mealParameters: Seq[MealParameters]
  ): Prop = {
    val lengthProp =
      (meals.length ?= mealParameters.length) :| "Correct number of meals"
    // TODO: This is a simplified assumption.
    //       It is possible for multiple meals to have the same date, and name, but contain different entries.
    //       The test could be extended by also comparing the recipe ids and amounts of the entries,
    //       which would lead to a sufficient equality in the sense that all comparable components are equal.
    //       In the current setting meal creations do not have uniquely identifying properties.
    val expectedDatesAndNames =
      mealParameters
        .map(mp => (mp.mealCreation.date, mp.mealCreation.name))
        .sorted

    val actualDatesAndNames =
      meals
        .map(meal => (meal.date, meal.name))
        .sorted

    Prop.all(
      lengthProp,
      actualDatesAndNames ?= expectedDatesAndNames
    )
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests)

}
