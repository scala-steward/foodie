package services.recipe

import cats.data.EitherT
import config.TestConfiguration
import db.IngredientId
import errors.{ ErrorContext, ServerError }
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.user.{ User, UserService }
import services.{ DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object RecipeServiceProperties extends Properties("Recipe service") {

  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
  private val userService   = TestUtil.injector.instanceOf[UserService]

  private def setupUserAndRecipe(user: User, recipe: Recipe): Future[Unit] =
    for {
      _ <- userService.add(user)
      _ <- ServiceFunctions.create(user.id, recipe)
    } yield ()

  property("Creation") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeCreationGen :| "recipe"
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
    Gens.recipeGen :| "recipe"
  ) { (user, recipe) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      _ <- EitherT.liftF(
        ServiceFunctions.create(
          user.id,
          recipe
        )
      )
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(user.id, recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      fetchedRecipe ?= recipe
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read all") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gen.listOf(Gens.recipeGen) :| "recipes"
  ) { (user, recipes) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      _ <- EitherT.liftF(
        ServiceFunctions.createAll(
          user.id,
          recipes
        )
      )
      fetchedRecipes <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
        recipeService.allRecipes(user.id)
      )
    } yield {
      fetchedRecipes.sortBy(_.id) ?= recipes.sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class UpdateSetup(
      user: User,
      recipe: Recipe,
      recipeUpdate: RecipeUpdate
  )

  private val updateSetupGen: Gen[UpdateSetup] =
    for {
      user         <- GenUtils.userWithFixedPassword
      recipe       <- Gens.recipeGen
      recipeUpdate <- Gens.recipeUpdateGen(recipe.id)
    } yield UpdateSetup(
      user,
      recipe,
      recipeUpdate
    )

  property("Update") = Prop.forAll(
    updateSetupGen :| "update setup"
  ) { updateSetup =>
    DBTestUtil.clearDb()
    val transformer = for {
      _             <- EitherT.liftF(setupUserAndRecipe(updateSetup.user, updateSetup.recipe))
      updatedRecipe <- EitherT(recipeService.updateRecipe(updateSetup.user.id, updateSetup.recipeUpdate))
      fetchedRecipe <- EitherT.fromOptionF(
        recipeService.getRecipe(updateSetup.user.id, updateSetup.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield {
      val expectedRecipe = RecipeUpdate.update(updateSetup.recipe, updateSetup.recipeUpdate)
      Prop.all(
        updatedRecipe ?= expectedRecipe,
        fetchedRecipe ?= expectedRecipe
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Delete") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.recipeGen :| "recipe"
  ) { (user, recipe) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      _ <- EitherT.liftF(
        ServiceFunctions.create(
          user.id,
          recipe = recipe
        )
      )
      result  <- EitherT.liftF[Future, ServerError, Boolean](recipeService.deleteRecipe(user.id, recipe.id))
      fetched <- EitherT.liftF[Future, ServerError, Option[Recipe]](recipeService.getRecipe(user.id, recipe.id))
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
    Gens.fullRecipeGen() :| "full recipe",
    Gens.ingredientGen :| "ingredient"
  ) { (user, fullRecipe, ingredient) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      _ <- EitherT.liftF(
        ServiceFunctions.createFull(
          user.id,
          fullRecipe
        )
      )
      ingredientCreation = IngredientCreation(fullRecipe.recipe.id, ingredient.foodId, ingredient.amountUnit)
      ingredient <- EitherT(recipeService.addIngredient(user.id, ingredientCreation))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(user.id, fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredient = IngredientCreation.create(ingredient.id, ingredientCreation)
      ingredients.sortBy(_.id) ?= (expectedIngredient +: fullRecipe.ingredients).sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Read ingredients") = Prop.forAll(
    GenUtils.userWithFixedPassword :| "user",
    Gens.fullRecipeGen() :| "full recipe"
  ) { (user, fullRecipe) =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(user))
      _ <- EitherT.liftF(
        ServiceFunctions.createFull(
          user.id,
          fullRecipe
        )
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(user.id, fullRecipe.recipe.id)
      )
    } yield {
      ingredients.sortBy(_.id) ?= fullRecipe.ingredients.sortBy(_.id)
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class IngredientUpdateSetup(
      user: User,
      fullRecipe: FullRecipe,
      ingredient: Ingredient,
      ingredientUpdate: IngredientUpdate
  )

  private val ingredientUpdateSetupGen: Gen[IngredientUpdateSetup] =
    for {
      user             <- GenUtils.userWithFixedPassword
      fullRecipe       <- Gens.fullRecipeGen()
      ingredient       <- Gen.oneOf(fullRecipe.ingredients)
      ingredientUpdate <- Gens.ingredientUpdateGen(ingredient.id, ingredient.foodId)
    } yield IngredientUpdateSetup(
      user = user,
      fullRecipe = fullRecipe,
      ingredient = ingredient,
      ingredientUpdate = ingredientUpdate
    )

  property("Update ingredient") = Prop.forAll(
    ingredientUpdateSetupGen :| "ingredient update setup"
  ) { ingredientUpdateSetup =>
    DBTestUtil.clearDb()

    val transformer = for {
      _ <- EitherT.liftF(userService.add(ingredientUpdateSetup.user))
      _ <- EitherT.liftF(
        ServiceFunctions.createFull(
          ingredientUpdateSetup.user.id,
          ingredientUpdateSetup.fullRecipe
        )
      )
      updatedIngredient <-
        EitherT(recipeService.updateIngredient(ingredientUpdateSetup.user.id, ingredientUpdateSetup.ingredientUpdate))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(ingredientUpdateSetup.user.id, ingredientUpdateSetup.fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredient = IngredientUpdate.update(
        ingredientUpdateSetup.ingredient,
        ingredientUpdateSetup.ingredientUpdate
      )
      val expectedIngredients =
        ingredientUpdateSetup.fullRecipe.ingredients.map { ingredient =>
          if (ingredient.id == ingredientUpdateSetup.ingredient.id) expectedIngredient
          else ingredient
        }
      Prop.all(
        (updatedIngredient ?= expectedIngredient) :| "Update correct",
        (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class DeleteIngredientSetup(
      user: User,
      fullRecipe: FullRecipe,
      ingredientId: IngredientId
  )

  private val deleteIngredientSetupGen: Gen[DeleteIngredientSetup] =
    for {
      user         <- GenUtils.userWithFixedPassword
      fullRecipe   <- Gens.fullRecipeGen()
      ingredientId <- Gen.oneOf(fullRecipe.ingredients).map(_.id)
    } yield DeleteIngredientSetup(
      user = user,
      fullRecipe = fullRecipe,
      ingredientId = ingredientId
    )

  property("Delete ingredient") = Prop.forAll(
    deleteIngredientSetupGen :| "delete ingredient setup"
  ) { setup =>
    DBTestUtil.clearDb()

    val transformer = for {
      _ <- EitherT.liftF(userService.add(setup.user))
      _ <- EitherT.liftF(
        ServiceFunctions.createFull(
          setup.user.id,
          setup.fullRecipe
        )
      )
      deletionResult <- EitherT.liftF(recipeService.removeIngredient(setup.user.id, setup.ingredientId))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(setup.user.id, setup.fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredients = setup.fullRecipe.ingredients.filter(_.id != setup.ingredientId)
      Prop.all(
        Prop(deletionResult) :| "Deletion successful",
        (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Creation (wrong user)") = Prop.forAll(
    GenUtils.twoUsersGen :| "users",
    Gens.recipeCreationGen :| "recipe creation"
  ) {
    case ((user1, user2), recipeCreation) =>
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
    GenUtils.twoUsersGen :| "users",
    Gens.recipeGen :| "recipe"
  ) {
    case ((user1, user2), recipe) =>
      DBTestUtil.clearDb()
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user1))
        _ <- EitherT.liftF(userService.add(user2))
        _ <- EitherT.liftF(
          ServiceFunctions.create(
            user1.id,
            recipe = recipe
          )
        )
        fetchedRecipe <- EitherT.liftF[Future, ServerError, Option[Recipe]](
          recipeService.getRecipe(user2.id, recipe.id)
        )
      } yield {
        Prop(fetchedRecipe.isEmpty) :| "Access denied"
      }

      DBTestUtil.awaitProp(transformer)
  }

  property("Read all (wrong user)") = Prop.forAll(
    GenUtils.twoUsersGen :| "users",
    Gen.listOf(Gens.recipeGen) :| "recipes"
  ) {
    case ((user1, user2), recipes) =>
      DBTestUtil.clearDb()
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user1))
        _ <- EitherT.liftF(userService.add(user2))
        _ <- EitherT.liftF(ServiceFunctions.createAll(user1.id, recipes))
        fetchedRecipes <- EitherT.liftF[Future, ServerError, Seq[Recipe]](
          recipeService.allRecipes(user2.id)
        )
      } yield {
        fetchedRecipes ?= Seq.empty
      }

      DBTestUtil.awaitProp(transformer)
  }

  private case class WrongUpdateSetup(
      user1: User,
      user2: User,
      recipe: Recipe,
      recipeUpdate: RecipeUpdate
  )

  private val wrongUpdateSetupGen: Gen[WrongUpdateSetup] =
    for {
      (user1, user2) <- GenUtils.twoUsersGen
      recipe         <- Gens.recipeGen
      recipeUpdate   <- Gens.recipeUpdateGen(recipe.id)
    } yield WrongUpdateSetup(
      user1,
      user2,
      recipe,
      recipeUpdate
    )

  property("Update (wrong user)") = Prop.forAll(
    wrongUpdateSetupGen :| "update setup"
  ) {
    case WrongUpdateSetup(user1, user2, recipe, update) =>
      DBTestUtil.clearDb()
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user1))
        _ <- EitherT.liftF(userService.add(user2))
        _ <- EitherT.liftF(
          ServiceFunctions.create(
            user1.id,
            recipe = recipe
          )
        )
        updatedRecipe <-
          EitherT.liftF[Future, ServerError, ServerError.Or[Recipe]](recipeService.updateRecipe(user2.id, update))
      } yield {
        Prop(updatedRecipe.isLeft)
      }

      DBTestUtil.awaitProp(transformer)
  }

  property("Delete (wrong user)") = Prop.forAll(
    GenUtils.twoUsersGen :| "users",
    Gens.recipeGen :| "recipe"
  ) {
    case ((user1, user2), recipe) =>
      DBTestUtil.clearDb()
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user1))
        _ <- EitherT.liftF(userService.add(user2))
        _ <- EitherT.liftF(
          ServiceFunctions.create(
            user1.id,
            recipe = recipe
          )
        )
        result <- EitherT.liftF[Future, ServerError, Boolean](recipeService.deleteRecipe(user2.id, recipe.id))
      } yield {
        Prop(!result) :| "Deletion failed"
      }

      DBTestUtil.awaitProp(transformer)
  }

  property("Add ingredient (wrong user)") = Prop.forAll(
    GenUtils.twoUsersGen :| "users",
    Gens.fullRecipeGen() :| "full recipe",
    Gens.ingredientGen :| "ingredient"
  ) {
    case ((user1, user2), fullRecipe, ingredient) =>
      DBTestUtil.clearDb()
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user1))
        _ <- EitherT.liftF(userService.add(user2))
        _ <- EitherT.liftF(
          ServiceFunctions.createFull(
            user1.id,
            fullRecipe
          )
        )
        ingredientCreation = IngredientCreation(fullRecipe.recipe.id, ingredient.foodId, ingredient.amountUnit)
        result <- EitherT.liftF(recipeService.addIngredient(user2.id, ingredientCreation))
        ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
          recipeService.getIngredients(user1.id, fullRecipe.recipe.id)
        )
      } yield {
        Prop.all(
          Prop(result.isLeft) :| "Ingredient addition failed",
          ingredients.sortBy(_.id) ?= fullRecipe.ingredients.sortBy(_.id)
        )
      }

      DBTestUtil.awaitProp(transformer)
  }

  property("Read ingredients (wrong user)") = Prop.forAll(
    GenUtils.twoUsersGen :| "users",
    Gens.fullRecipeGen() :| "full recipe"
  ) {
    case ((user1, user2), fullRecipe) =>
      DBTestUtil.clearDb()
      val transformer = for {
        _ <- EitherT.liftF(userService.add(user1))
        _ <- EitherT.liftF(userService.add(user2))
        _ <- EitherT.liftF(
          ServiceFunctions.createFull(
            user1.id,
            fullRecipe
          )
        )
        ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
          recipeService.getIngredients(user2.id, fullRecipe.recipe.id)
        )
      } yield {
        ingredients.sortBy(_.id) ?= List.empty
      }

      DBTestUtil.awaitProp(transformer)
  }

  private case class WrongIngredientUpdateSetup(
      user1: User,
      user2: User,
      fullRecipe: FullRecipe,
      ingredientUpdate: IngredientUpdate
  )

  private val wrongIngredientUpdateSetupGen: Gen[WrongIngredientUpdateSetup] =
    for {
      (user1, user2)   <- GenUtils.twoUsersGen
      fullRecipe       <- Gens.fullRecipeGen()
      ingredient       <- Gen.oneOf(fullRecipe.ingredients)
      ingredientUpdate <- Gens.ingredientUpdateGen(ingredient.id, ingredient.foodId)
    } yield WrongIngredientUpdateSetup(
      user1 = user1,
      user2 = user2,
      fullRecipe = fullRecipe,
      ingredientUpdate = ingredientUpdate
    )

  property("Update ingredient (wrong user)") = Prop.forAll(
    wrongIngredientUpdateSetupGen :| "ingredient update setup"
  ) { wrongIngredientUpdateSetup =>
    DBTestUtil.clearDb()

    val transformer = for {
      _ <- EitherT.liftF(userService.add(wrongIngredientUpdateSetup.user1))
      _ <- EitherT.liftF(userService.add(wrongIngredientUpdateSetup.user2))
      _ <- EitherT.liftF(
        ServiceFunctions.createFull(
          wrongIngredientUpdateSetup.user1.id,
          wrongIngredientUpdateSetup.fullRecipe
        )
      )
      result <- EitherT.liftF(
        recipeService.updateIngredient(wrongIngredientUpdateSetup.user2.id, wrongIngredientUpdateSetup.ingredientUpdate)
      )
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService
          .getIngredients(wrongIngredientUpdateSetup.user1.id, wrongIngredientUpdateSetup.fullRecipe.recipe.id)
      )
    } yield {
      Prop.all(
        Prop(result.isLeft) :| "Ingredient update failed",
        (ingredients.sortBy(_.id) ?= wrongIngredientUpdateSetup.fullRecipe.ingredients.sortBy(
          _.id
        )) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  private case class WrongDeleteIngredientSetup(
      user1: User,
      user2: User,
      fullRecipe: FullRecipe,
      ingredientId: IngredientId
  )

  private val wrongDeleteIngredientSetupGen: Gen[WrongDeleteIngredientSetup] =
    for {
      (user1, user2) <- GenUtils.twoUsersGen
      fullRecipe     <- Gens.fullRecipeGen()
      ingredientId   <- Gen.oneOf(fullRecipe.ingredients).map(_.id)
    } yield WrongDeleteIngredientSetup(
      user1 = user1,
      user2 = user2,
      fullRecipe = fullRecipe,
      ingredientId = ingredientId
    )

  property("Delete ingredient (wrong user)") = Prop.forAll(
    wrongDeleteIngredientSetupGen :| "wrong delete ingredient setup"
  ) { setup =>
    DBTestUtil.clearDb()
    val transformer = for {
      _ <- EitherT.liftF(userService.add(setup.user1))
      _ <- EitherT.liftF(userService.add(setup.user2))
      _ <- EitherT.liftF(
        ServiceFunctions.createFull(
          setup.user1.id,
          setup.fullRecipe
        )
      )
      deletionResult <- EitherT.liftF(recipeService.removeIngredient(setup.user2.id, setup.ingredientId))
      ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
        recipeService.getIngredients(setup.user1.id, setup.fullRecipe.recipe.id)
      )
    } yield {
      val expectedIngredients = setup.fullRecipe.ingredients
      Prop.all(
        Prop(!deletionResult) :| "Ingredient deletion failed",
        (ingredients.sortBy(_.id) ?= expectedIngredients.sortBy(_.id)) :| "Ingredients after update correct"
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests)

}
