package services.duplication.meal

import cats.data.{ EitherT, NonEmptyList }
import db._
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.common.RequestInterval
import services.meal.{ FullMeal, Meal, MealEntry, MealService }
import services.recipe.Recipe
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object MealDuplicationProperties extends Properties("Meal duplication") {

  case class Services(
      mealService: MealService,
      duplication: Duplication
  )

  def servicesWith(
      userId: UserId,
      fullMeal: FullMeal
  ): Services = {
    val mealDao      = DAOTestInstance.Meal.instanceFrom(ContentsUtil.Meal.from(userId, Seq(fullMeal.meal)))
    val mealEntryDao = DAOTestInstance.MealEntry.instanceFrom(ContentsUtil.MealEntry.from(fullMeal))

    val mealServiceCompanion = new services.meal.Live.Companion(
      mealDao = mealDao,
      mealEntryDao = mealEntryDao
    )

    Services(
      mealService = new services.meal.Live(
        TestUtil.databaseConfigProvider,
        mealServiceCompanion
      ),
      duplication = new services.duplication.meal.Live(
        TestUtil.databaseConfigProvider,
        new services.duplication.meal.Live.Companion(
          mealServiceCompanion,
          mealEntryDao
        ),
        mealServiceCompanion = mealServiceCompanion
      )
    )
  }

  private case class DuplicationSetup(
      userId: UserId,
      recipes: List[Recipe],
      fullMeal: FullMeal
  )

  private val duplicationSetupGen: Gen[DuplicationSetup] = for {
    userId   <- GenUtils.taggedId[UserTag]
    recipes  <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    fullMeal <- services.meal.Gens.fullMealGen(NonEmptyList.fromListUnsafe(recipes.map(_.id)))
  } yield DuplicationSetup(
    userId = userId,
    recipes = recipes,
    fullMeal = fullMeal
  )

  private case class MealEntryValues(
      recipeId: RecipeId,
      numberOfServings: BigDecimal
  )

  private def groupMealEntries(mealEntries: Seq[MealEntry]): Map[RecipeId, List[MealEntryValues]] =
    mealEntries
      .groupBy(_.recipeId)
      .view
      .mapValues(
        _.sortBy(_.numberOfServings)
          .map(mealEntry => MealEntryValues(mealEntry.recipeId, mealEntry.numberOfServings))
          .toList
      )
      .toMap

  property("Duplication produces expected result") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      fullMeal = setup.fullMeal
    )
    val transformer = for {
      duplicatedMeal <- EitherT(services.duplication.duplicate(setup.userId, setup.fullMeal.meal.id))
      mealEntries <- EitherT
        .liftF[Future, ServerError, Map[MealId, Seq[MealEntry]]](
          services.mealService.getMealEntries(setup.userId, Seq(duplicatedMeal.id))
        )
        .map(_.getOrElse(duplicatedMeal.id, List.empty))
    } yield {
      Prop.all(
        groupMealEntries(mealEntries) ?= groupMealEntries(setup.fullMeal.mealEntries),
        duplicatedMeal.name.exists { name =>
          setup.fullMeal.meal.name.fold(name.startsWith("(copy"))(name.startsWith)
        }
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication adds value") = Prop.forAll(duplicationSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      fullMeal = setup.fullMeal
    )
    val transformer = for {
      allMealsBefore <- EitherT.liftF[Future, ServerError, Seq[Meal]](
        services.mealService.allMeals(setup.userId, RequestInterval(None, None))
      )
      duplicated <- EitherT(services.duplication.duplicate(setup.userId, setup.fullMeal.meal.id))
      allMealsAfter <- EitherT.liftF[Future, ServerError, Seq[Meal]](
        services.mealService.allMeals(setup.userId, RequestInterval(None, None))
      )
    } yield {
      allMealsAfter.map(_.id).sorted ?= (allMealsBefore :+ duplicated).map(_.id).sorted
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Duplication fails for wrong user id") = Prop.forAll(
    duplicationSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val services = servicesWith(
      userId = setup.userId,
      fullMeal = setup.fullMeal
    )
    val propF = for {
      result <- services.duplication.duplicate(userId2, setup.fullMeal.meal.id)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }
}
