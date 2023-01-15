package services.complex.food

import db.{ ComplexFoodId, DAOTestInstance, RecipeId, UserId, UserTag }
import org.scalacheck.{ Gen, Prop, Properties }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import services.recipe.{ Ingredient, Recipe, RecipeServiceProperties }
import Prop.AnyOperators
import cats.data.{ EitherT, NonEmptyList }
import db.generated.Tables
import io.scalaland.chimney.dsl._
import services.stats.PropUtil
import GenUtils.implicits._
import errors.ErrorContext

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ComplexFoodServiceProperties extends Properties("Complex food service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)]
  ): Live.Companion =
    new Live.Companion(
      recipeService = RecipeServiceProperties.companionWith(
        recipeContents = recipeContents,
        ingredientContents = Seq.empty
      ),
      dao = DAOTestInstance.ComplexFood.instanceFrom(complexFoodContents)
    )

  private def complexFoodServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)]
  ): ComplexFoodService =
    new Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        complexFoodContents = complexFoodContents
      )
    )

  private def toComplexFood(complexFoodIncoming: ComplexFoodIncoming, recipe: Recipe): ComplexFood =
    (complexFoodIncoming.transformInto[Tables.ComplexFoodRow], recipe).transformInto[ComplexFood]

  private case class SetupBase(
      userId: UserId,
      recipes: Seq[Recipe],
      complexFoods: Seq[ComplexFoodIncoming]
  )

  private val setupBaseGen: Gen[SetupBase] = for {
    userId        <- GenUtils.taggedId[UserTag]
    recipes       <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    recipesSubset <- GenUtils.nonEmptySubset(NonEmptyList.fromListUnsafe(recipes.map(_.id)))
    complexFoods  <- recipesSubset.traverse(Gens.complexFood)
  } yield SetupBase(
    userId = userId,
    recipes = recipes,
    complexFoods = complexFoods.toList
  )

  private case class FetchAllSetup(
      userId: UserId,
      recipes: Seq[Recipe],
      complexFoods: Seq[ComplexFoodIncoming]
  )

  private val fetchAllSetupGen: Gen[FetchAllSetup] = for {
    base <- setupBaseGen
  } yield FetchAllSetup(
    userId = base.userId,
    recipes = base.recipes,
    complexFoods = base.complexFoods.toList
  )

  property("Fetch all") = Prop.forAll(fetchAllSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.complexFoods)
    )
    val recipeMap = setup.recipes.map(recipe => recipe.id -> recipe).toMap
    val propF = for {
      all <- complexFoodService.all(setup.userId)
    } yield {
      val expected = setup.complexFoods.map { complexFoodIncoming =>
        toComplexFood(complexFoodIncoming, recipeMap(complexFoodIncoming.recipeId))
      }
      all.sortBy(_.recipeId) ?= expected.sortBy(_.recipeId)
    }

    DBTestUtil.await(propF)
  }

  private case class FetchSingleSetup(
      userId: UserId,
      recipes: Seq[Recipe],
      complexFoods: Seq[ComplexFoodIncoming],
      complexFoodId: ComplexFoodId
  )

  private val fetchSingleSetupGen: Gen[FetchSingleSetup] = for {
    base          <- setupBaseGen
    complexFoodId <- Gen.oneOf(base.complexFoods.map(_.recipeId))
  } yield FetchSingleSetup(
    userId = base.userId,
    recipes = base.recipes,
    complexFoods = base.complexFoods,
    complexFoodId = complexFoodId
  )

  property("Fetch single") = Prop.forAll(fetchSingleSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.complexFoods)
    )
    val transformer = for {
      complexFood <- EitherT.fromOptionF(
        complexFoodService.get(setup.userId, setup.complexFoodId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
      recipe <- EitherT.fromOption[Future](
        setup.recipes.find(_.id == setup.complexFoodId),
        ErrorContext.Recipe.NotFound.asServerError
      )
      preExpected <- EitherT.fromOption[Future](
        setup.complexFoods.find(_.recipeId == setup.complexFoodId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = toComplexFood(preExpected, recipe)
      complexFood ?= expected
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class CreationSetup(
      userId: UserId,
      recipe: Recipe,
      complexFoodIncoming: ComplexFoodIncoming
  )

  private val creationSetupGen: Gen[CreationSetup] = for {
    userId              <- GenUtils.taggedId[UserTag]
    recipe              <- services.recipe.Gens.recipeGen
    complexFoodIncoming <- Gens.complexFood(recipe.id)
  } yield CreationSetup(
    userId = userId,
    recipe = recipe,
    complexFoodIncoming = complexFoodIncoming
  )

  property("Creation (success)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty
    )
    val transformer = for {
      inserted <- EitherT(complexFoodService.create(setup.userId, setup.complexFoodIncoming))
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(setup.userId, setup.complexFoodIncoming.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = toComplexFood(setup.complexFoodIncoming, setup.recipe)
      Prop.all(
        inserted ?= expected,
        fetched ?= expected
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Creation (failure)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(Seq(setup.complexFoodIncoming))
    )
    val propF = for {
      created <- complexFoodService.create(setup.userId, setup.complexFoodIncoming)
    } yield created.isLeft

    DBTestUtil.await(propF)
  }

  property("Update") = ???
  property("Delete") = ???

  property("Fetch all (wrong user)") = ???
  property("Fetch single (wrong user)") = ???
  property("Creation (wrong user)") = ???
  property("Update (wrong user)") = ???
  property("Delete (wrong user)") = ???
}
