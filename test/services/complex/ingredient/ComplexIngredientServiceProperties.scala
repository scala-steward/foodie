package services.complex.ingredient

import cats.data.EitherT
import db._
import errors.{ErrorContext, ServerError}
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{Gen, Prop, Properties}
import services.complex.food.ComplexFoodIncoming
import services.recipe.Recipe
import services.{ContentsUtil, DBTestUtil, GenUtils, TestUtil}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ComplexIngredientServiceProperties extends Properties("Complex ingredient service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): Live.Companion =
    new Live.Companion(
      recipeDao = DAOTestInstance.Recipe.instanceFrom(recipeContents),
      complexFoodDao = DAOTestInstance.ComplexFood.instanceFrom(complexFoodContents),
      complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(complexIngredientContents)
    )

  private def complexIngredientServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): ComplexIngredientService =
    new Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        complexFoodContents = complexFoodContents,
        complexIngredientContents = complexIngredientContents
      )
    )

  private case class SetupBase(
      userId: UserId,
      recipe: Recipe,                                           // current recipe
      recipesAsComplexFoods: Seq[(Recipe, ComplexFoodIncoming)] // recipes that are available as complex ingredients
  )

  private val setupBaseGen: Gen[SetupBase] = for {
    userId <- GenUtils.taggedId[UserTag]
    recipe <- services.recipe.Gens.recipeGen
    recipesAsComplexFoods <- Gen.nonEmptyListOf {
      for {
        recipe      <- services.recipe.Gens.recipeGen
        complexFood <- services.complex.food.Gens.complexFood(recipe.id)
      } yield recipe -> complexFood
    }
  } yield {
    SetupBase(
      userId = userId,
      recipe = recipe,
      recipesAsComplexFoods = recipesAsComplexFoods
    )
  }

  private case class FetchAllSetup(
      base: SetupBase,
      complexIngredients: Seq[ComplexIngredient]
  )

  private val fetchAllSetupGen: Gen[FetchAllSetup] = for {
    setupBase <- setupBaseGen
    complexIngredients <-
      Gens.complexIngredientsGen(setupBase.recipe.id, setupBase.recipesAsComplexFoods.map(_._1.id)) // As intended
  } yield FetchAllSetup(
    base = setupBase,
    complexIngredients = complexIngredients
  )

  property("Fetch all") = Prop.forAll(fetchAllSetupGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents = ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, setup.complexIngredients)
    )
    val propF = for {
      fetched <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
    } yield fetched.sortBy(_.complexFoodId) ?= setup.complexIngredients.sortBy(_.complexFoodId)
    DBTestUtil.await(propF)
  }

  private case class CreateSuccessSetup(
      base: SetupBase,
      complexIngredient: ComplexIngredient
  )

  private val createSuccessSetupGen: Gen[CreateSuccessSetup] = for {
    base              <- setupBaseGen
    complexIngredient <- Gens.complexIngredientGen(base.recipe.id, base.recipesAsComplexFoods.map(_._1.id))
  } yield CreateSuccessSetup(
    base = base,
    complexIngredient = complexIngredient
  )

  property("Create (success)") = Prop.forAll(createSuccessSetupGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      created <- EitherT(complexIngredientService.create(setup.base.userId, setup.complexIngredient))
      fetched <- EitherT.liftF[Future, ServerError, Seq[ComplexIngredient]](
        complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
      )
    } yield {
      Prop.all(
        created ?= setup.complexIngredient,
        fetched ?= Seq(setup.complexIngredient)
      )
    }

    DBTestUtil.awaitProp(transformer)
  }
//  property("Create (failure, exists)") = ???
//  property("Create (failure, cycle)") = ???
//  property("Update (success)") = ???
//  property("Update (failure)") = ???
//  property("Delete (existent)") = ???
//  property("Delete (non-existent)") = ???
//
//  property("Fetch all (wrong user)") = ???
//  property("Create (wrong user)") = ???
//  property("Update (wrong user)") = ???
//  property("Delete (wrong user)") = ???

}
