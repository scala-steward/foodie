package services.complex.food

import db.{ DAOTestInstance, RecipeId, UserId }
import org.scalacheck.Properties
import services.TestUtil
import services.recipe.{ Ingredient, Recipe, RecipeServiceProperties }

import scala.concurrent.ExecutionContext.Implicits.global

object ComplexFoodServiceProperties extends Properties("Complex food service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(RecipeId, Ingredient)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)]
  ): Live.Companion =
    new Live.Companion(
      recipeService = RecipeServiceProperties.companionWith(
        recipeContents = recipeContents,
        ingredientContents = ingredientContents
      ),
      dao = DAOTestInstance.ComplexFood.instanceFrom(complexFoodContents)
    )

  private def complexFoodServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(RecipeId, Ingredient)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)]
  ): ComplexFoodService =
    new Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        ingredientContents = ingredientContents,
        complexFoodContents = complexFoodContents
      )
    )

  property("Fetch all") = ???
  property("Fetch single") = ???
  property("Creation") = ???
  property("Update") = ???
  property("Delete") = ???
  property("Fetch all (wrong user)") = ???
  property("Fetch single (wrong user)") = ???
  property("Creation (wrong user)") = ???
  property("Update (wrong user)") = ???
  property("Delete (wrong user)") = ???
}
