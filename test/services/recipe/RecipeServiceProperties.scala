package services.recipe

import cats.data.EitherT
import config.TestConfiguration
import errors.{ ErrorContext, ServerError }
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.stats.ServiceFunctions
import services.{ DBTestUtil, GenUtils, TestUtil }
import services.user.{ User, UserService }
import cats.syntax.traverse._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object RecipeServiceProperties extends Properties("Recipe service") {

  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
  private val userService   = TestUtil.injector.instanceOf[UserService]

  property("Creation") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeCreationGen :| "recipe creation"
  ) { (user, recipeCreation) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _             <- EitherT.liftF(userService.add(user))
      createdRecipe <- EitherT(recipeService.createRecipe(user.id, recipeCreation))
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(user.id, createdRecipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val expectedRecipe = RecipeCreation.create(createdRecipe.id, recipeCreation)
      Prop.all(
        createdRecipe ?= expectedRecipe,
        fetchedRecipe ?= expectedRecipe
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read single") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeCreationGen :| "recipe creation"
  ) { (user, recipeCreation) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user.id,
        RecipeParameters(
          recipeCreation = recipeCreation,
          ingredientParameters = List.empty
        )
      )
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(user.id, insertedRecipe.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      fetchedRecipe ?= insertedRecipe.recipe
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read all") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gen.listOf(Gens.recipeCreationGen) :| "recipe creations"
  ) { (user, recipeCreations) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      insertedRecipes <- recipeCreations.traverse { recipeCreation =>
        ServiceFunctions.createRecipe(recipeService)(
          user.id,
          RecipeParameters(
            recipeCreation = recipeCreation,
            ingredientParameters = List.empty
          )
        )
      }
      fetchedRecipes <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        recipeService.allRecipes(user.id)
      )
    } yield {
      fetchedRecipes.sortBy(_.id) ?= insertedRecipes.map(_.recipe).sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

//  property("Update") = ???
  property("Delete") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeCreationGen :| "recipe creation"
  ) { (user, recipeCreation) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user.id,
        RecipeParameters(
          recipeCreation = recipeCreation,
          ingredientParameters = List.empty
        )
      )
      result <-
        EitherT.liftF[Future, ServerError, Boolean](recipeService.deleteRecipe(user.id, insertedRecipe.recipe.id))
      fetched <-
        EitherT.liftF[Future, ServerError, Option[Recipe]](recipeService.getRecipe(user.id, insertedRecipe.recipe.id))
    } yield {
      Prop.all(
        Prop(result) :| "Deletion successful",
        Prop(fetched.isEmpty) :| "Recipe should be deleted"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }
//
//  property("Add ingredient") = ???
//  property("Read ingredients") = ???
//  property("Update ingredient") = ???
//  property("Delete ingredient") = ???
//
//  property("Creation (wrong user)") = ???
//  property("Read single (wrong user)") = ???
//  property("Read all (wrong user)") = ???
//  property("Update (wrong user)") = ???
//  property("Delete (wrong user)") = ???
//
//  property("Add ingredient (wrong user)") = ???
//  property("Read ingredients (wrong user)") = ???
//  property("Update ingredient (wrong user)") = ???
//  property("Delete ingredient (wrong user)") = ???

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests)

}
