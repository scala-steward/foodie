package services.recipe

import cats.data.EitherT
import cats.syntax.traverse._
import config.TestConfiguration
import errors.{ ErrorContext, ServerError }
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.stats.ServiceFunctions
import services.user.UserService
import services.{ DBTestUtil, GenUtils, TestUtil }

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

  property("Update") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeCreationGen :| "recipe creation",
    Gens.recipePreUpdateGen :| "recipe pre-update"
  ) { (user, recipeCreation, preUpdate) =>
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
      recipeUpdate = RecipePreUpdate.toUpdate(insertedRecipe.recipe.id, preUpdate)
      updatedRecipe <- EitherT(recipeService.updateRecipe(user.id, recipeUpdate))
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(user.id, insertedRecipe.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val expectedRecipe = RecipeUpdate.update(insertedRecipe.recipe, recipeUpdate)
      Prop.all(
        updatedRecipe ?= expectedRecipe,
        fetchedRecipe ?= expectedRecipe
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

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

  property("Add ingredient") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeParametersGen() :| "recipe parameters",
    Gens.ingredientGen :| "ingredient"
  ) { (user, recipeParameters, ingredientParameters) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user.id,
        recipeParameters
      )
      ingredientCreation =
        IngredientPreCreation.toCreation(insertedRecipe.recipe.id, ingredientParameters.ingredientPreCreation)
      ingredient <- EitherT(recipeService.addIngredient(user.id, ingredientCreation))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(user.id, insertedRecipe.recipe.id)
      )
    } yield {
      val expectedIngredient = IngredientCreation.create(ingredient.id, ingredientCreation)
      ingredients.sortBy(_.id) ?= (expectedIngredient +: insertedRecipe.ingredients).sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read ingredients") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeParametersGen() :| "recipe parameters"
  ) { (user, recipeParameters) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user.id,
        recipeParameters
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(user.id, insertedRecipe.recipe.id)
      )
    } yield {
      ingredients.sortBy(_.id) ?= insertedRecipe.ingredients.sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Update ingredient") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeParametersGen() :| "recipe parameters"
  ) { (user, recipeParameters) =>
    DBTestUtil.clearDb()
    Prop.forAll(
      Gen
        .oneOf(recipeParameters.ingredientParameters.zipWithIndex)
        .flatMap {
          case (ingredientParameters, index) =>
            Gens
              .ingredientPreUpdateGen(ingredientParameters.ingredientPreCreation.foodId)
              .map(index -> _)
        } :| "index and pre-update"
    ) {
      case (index, preUpdate) =>
        val transformer = for {
          _ <- EitherT.liftF(userService.add(user))
          insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
            user.id,
            recipeParameters
          )
          ingredient       = insertedRecipe.ingredients.apply(index)
          ingredientUpdate = IngredientPreUpdate.toUpdate(ingredient.id, preUpdate)
          updatedIngredient <- EitherT(recipeService.updateIngredient(user.id, ingredientUpdate))
          ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
            recipeService.getIngredients(user.id, insertedRecipe.recipe.id)
          )
        } yield {
          val expectedIngredient  = IngredientUpdate.update(ingredient, ingredientUpdate)
          val expectedIngredients = insertedRecipe.ingredients.updated(index, expectedIngredient)
          Prop.all(
            (updatedIngredient ?= expectedIngredient) :| "Update correct",
            (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
          )
        }

        DBTestUtil.awaitProp(transformer)
    }
  }
  property("Delete ingredient") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeParametersGen() :| "recipe parameters"
  ) { (user, recipeParameters) =>
    DBTestUtil.clearDb()
    Prop.forAll(
      Gen
        .oneOf(recipeParameters.ingredientParameters.zipWithIndex)
        .map(_._2)
        :| "index"
    ) { index =>
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user))
        insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
          user.id,
          recipeParameters
        )
        ingredient = insertedRecipe.ingredients.apply(index)
        deletionResult <- EitherT.liftF(recipeService.removeIngredient(user.id, ingredient.id))
        ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
          recipeService.getIngredients(user.id, insertedRecipe.recipe.id)
        )
      } yield {
        val expectedIngredients = insertedRecipe.ingredients.zipWithIndex.filter(_._2 != index).map(_._1)
        Prop.all(
          Prop(deletionResult) :| "Deletion successful",
          (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
        )
      }

      DBTestUtil.awaitProp(transformer)
    }
  }
//
  property("Creation (wrong user)") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user1",
    GenUtils.userWithFixedPassword :| "user2",
    Gens.recipeCreationGen :| "recipe creation"
  ) { (user1, user2, recipeCreation) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _             <- EitherT.liftF(userService.add(user1))
      _             <- EitherT.liftF(userService.add(user2))
      createdRecipe <- EitherT(recipeService.createRecipe(user1.id, recipeCreation))
      fetchedRecipe <-
        EitherT.liftF[Future, ServerError, Option[Recipe]](recipeService.getRecipe(user2.id, createdRecipe.id))
    } yield {
      Prop(fetchedRecipe.isEmpty) :| "Access denied"
    }

    DBTestUtil.awaitProp(transformer)
  }
  property("Read single (wrong user)") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user1",
    GenUtils.userWithFixedPassword :| "user2",
    Gens.recipeCreationGen :| "recipe creation"
  ) { (user1, user2, recipeCreation) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user1))
      _ <- EitherT.liftF(userService.add(user2))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user1.id,
        RecipeParameters(
          recipeCreation = recipeCreation,
          ingredientParameters = List.empty
        )
      )
      fetchedRecipe <-
        EitherT.liftF[Future, ServerError, Option[Recipe]](recipeService.getRecipe(user2.id, insertedRecipe.recipe.id))
    } yield {
      Prop(fetchedRecipe.isEmpty) :| "Access denied"
    }

    DBTestUtil.awaitProp(transformer)
  }
  property("Read all (wrong user)") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user1",
    GenUtils.userWithFixedPassword :| "user2",
    Gen.listOf(Gens.recipeCreationGen) :| "recipe creations"
  ) { (user1, user2, recipeCreations) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user1))
      _ <- EitherT.liftF(userService.add(user2))
      _ <- recipeCreations.traverse { recipeCreation =>
        ServiceFunctions.createRecipe(recipeService)(
          user1.id,
          RecipeParameters(
            recipeCreation = recipeCreation,
            ingredientParameters = List.empty
          )
        )
      }
      fetchedRecipes <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        recipeService.allRecipes(user2.id)
      )
    } yield {
      fetchedRecipes ?= Seq.empty
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Update (wrong user)") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user1",
    GenUtils.userWithFixedPassword :| "user2",
    Gens.recipeCreationGen :| "recipe creation",
    Gens.recipePreUpdateGen :| "recipe pre-update"
  ) { (user1, user2, recipeCreation, preUpdate) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user1))
      _ <- EitherT.liftF(userService.add(user2))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user1.id,
        RecipeParameters(
          recipeCreation = recipeCreation,
          ingredientParameters = List.empty
        )
      )
      recipeUpdate = RecipePreUpdate.toUpdate(insertedRecipe.recipe.id, preUpdate)
      updatedRecipe <-
        EitherT.liftF[Future, ServerError, ServerError.Or[Recipe]](recipeService.updateRecipe(user2.id, recipeUpdate))
    } yield {
      Prop(updatedRecipe.isLeft)
    }

    DBTestUtil.awaitProp(transformer)
  }
  property("Delete (wrong user)") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user1",
    GenUtils.userWithFixedPassword :| "user2",
    Gens.recipeCreationGen :| "recipe creation"
  ) { (user1, user2, recipeCreation) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user1))
      _ <- EitherT.liftF(userService.add(user2))
      insertedRecipe <- ServiceFunctions.createRecipe(recipeService)(
        user1.id,
        RecipeParameters(
          recipeCreation = recipeCreation,
          ingredientParameters = List.empty
        )
      )
      result <-
        EitherT.liftF[Future, ServerError, Boolean](recipeService.deleteRecipe(user2.id, insertedRecipe.recipe.id))

    } yield {
      Prop(!result) :| "Deletion failed"
    }

    DBTestUtil.awaitProp(transformer)
  }
//
//  property("Add ingredient (wrong user)") = ???
//  property("Read ingredients (wrong user)") = ???
//  property("Update ingredient (wrong user)") = ???
//  property("Delete ingredient (wrong user)") = ???

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests)

}
