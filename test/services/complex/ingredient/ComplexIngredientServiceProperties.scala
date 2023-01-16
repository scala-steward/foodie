package services.complex.ingredient

import db._
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.recipe.Recipe
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global

object ComplexIngredientServiceProperties extends Properties("Complex ingredient service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): Live.Companion =
    new Live.Companion(
      recipeDao = DAOTestInstance.Recipe.instanceFrom(recipeContents),
      dao = DAOTestInstance.ComplexIngredient.instanceFrom(complexIngredientContents)
    )

  private def complexIngredientServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): ComplexIngredientService =
    new Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        complexIngredientContents = complexIngredientContents
      )
    )

  private case class SetupBase(
      userId: UserId,
      recipe: Recipe,       // current recipe
      recipes: Seq[Recipe], // recipes that are available as complex ingredients
      complexIngredients: Seq[ComplexIngredient]
  )

  private val setupBaseGen: Gen[SetupBase] = for {
    userId             <- GenUtils.taggedId[UserTag]
    recipe             <- services.recipe.Gens.recipeGen
    recipes            <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    complexIngredients <- Gens.complexIngredientsGen(recipe.id, recipes.map(_.id)) // As intended
  } yield {
    SetupBase(
      userId = userId,
      recipe = recipe,
      recipes = recipes,
      complexIngredients = complexIngredients
    )
  }

  property("Fetch all") = Prop.forAll(setupBaseGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexIngredientContents = ContentsUtil.ComplexIngredient.from(setup.recipe.id, setup.complexIngredients)
    )
    val propF = for {
      fetched <- complexIngredientService.all(setup.userId, setup.recipe.id)
    } yield fetched.sortBy(_.complexFoodId) ?= setup.complexIngredients.sortBy(_.complexFoodId)
    DBTestUtil.await(propF)
  }

//  property("Create (success)") = ???
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
