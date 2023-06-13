package services.complex.food

import cats.data.{ EitherT, NonEmptyList }
import config.TestConfiguration
import db._
import db.generated.Tables
import errors.ErrorContext
import io.scalaland.chimney.dsl._
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.GenUtils.implicits._
import services.complex.food.Gens.VolumeAmountOption
import services.complex.ingredient.ComplexIngredient
import services.recipe.{ Recipe, RecipeServiceProperties }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ComplexFoodServiceProperties extends Properties("Complex food service") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): Live.Companion =
    new Live.Companion(
      recipeService = RecipeServiceProperties.companionWith(
        recipeContents = recipeContents,
        ingredientContents = Seq.empty
      ),
      dao = DAOTestInstance.ComplexFood.instanceFrom(complexFoodContents),
      complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(complexIngredientContents)
    )

  private def complexFoodServiceWith(
      recipeContents: Seq[(UserId, Recipe)],
      complexFoodContents: Seq[(RecipeId, ComplexFoodIncoming)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): ComplexFoodService =
    new Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        complexFoodContents = complexFoodContents,
        complexIngredientContents = complexIngredientContents
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
    complexFoods  <- recipesSubset.traverse(Gens.complexFood(_, VolumeAmountOption.OptionalVolume))
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
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.complexFoods),
      complexIngredientContents = Seq.empty
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
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.complexFoods),
      complexIngredientContents = Seq.empty
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
    complexFoodIncoming <- Gens.complexFood(recipe.id, VolumeAmountOption.OptionalVolume)
  } yield CreationSetup(
    userId = userId,
    recipe = recipe,
    complexFoodIncoming = complexFoodIncoming
  )

  property("Creation (success)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
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
      complexFoodContents = ContentsUtil.ComplexFood.from(Seq(setup.complexFoodIncoming)),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      created <- complexFoodService.create(setup.userId, setup.complexFoodIncoming)
    } yield created.isLeft

    DBTestUtil.await(propF)
  }

  private case class UpdateSetup(
      creationSetup: CreationSetup,
      update: ComplexFoodIncoming
  )

  private val updateSetupGen: Gen[UpdateSetup] = for {
    creationSetup <- creationSetupGen
    update        <- Gens.complexFood(creationSetup.recipe.id, VolumeAmountOption.OptionalVolume)
  } yield UpdateSetup(
    creationSetup = creationSetup,
    update = update
  )

  property("Update (success)") = Prop.forAll(updateSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.creationSetup.userId, Seq(setup.creationSetup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(Seq(setup.creationSetup.complexFoodIncoming)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      updated <- EitherT(complexFoodService.update(setup.creationSetup.userId, setup.update))
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(setup.creationSetup.userId, setup.creationSetup.complexFoodIncoming.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = toComplexFood(setup.update, setup.creationSetup.recipe)
      Prop.all(
        updated ?= expected,
        fetched ?= expected
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Update (failure)") = Prop.forAll(updateSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.creationSetup.userId, Seq(setup.creationSetup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.update(setup.creationSetup.userId, setup.update)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

  property("Delete (existent)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(Seq(setup.complexFoodIncoming)),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result  <- complexFoodService.delete(setup.userId, setup.recipe.id)
      fetched <- complexFoodService.get(setup.userId, setup.recipe.id)
    } yield Prop.all(
      result,
      fetched.isEmpty
    )

    DBTestUtil.await(propF)
  }

  property("Delete (non-existent)") = Prop.forAll(creationSetupGen :| "setup") { setup =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.delete(setup.userId, setup.recipe.id)
    } yield !result

    DBTestUtil.await(propF)
  }

  property("Fetch all (wrong user)") = Prop.forAll(
    fetchAllSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.complexFoods),
      complexIngredientContents = Seq.empty
    )

    val propF = for {
      all <- complexFoodService.all(userId2)
    } yield {
      all.isEmpty
    }

    DBTestUtil.await(propF)
  }

  property("Fetch single (wrong user)") = Prop.forAll(
    fetchSingleSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, setup.recipes),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.complexFoods),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.get(userId2, setup.complexFoodId)
    } yield result.isEmpty

    DBTestUtil.await(propF)
  }

  property("Creation (wrong user)") = Prop.forAll(
    creationSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = Seq.empty,
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      result <- complexFoodService.create(userId2, setup.complexFoodIncoming)
    } yield result.isLeft

    DBTestUtil.await(propF)
  }

  property("Update (wrong user)") = Prop.forAll(
    updateSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.creationSetup.userId, Seq(setup.creationSetup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(Seq(setup.creationSetup.complexFoodIncoming)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      result <- EitherT.liftF(complexFoodService.update(userId2, setup.update))
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(setup.creationSetup.userId, setup.creationSetup.complexFoodIncoming.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = toComplexFood(setup.creationSetup.complexFoodIncoming, setup.creationSetup.recipe)
      Prop.all(
        result.isLeft,
        fetched ?= expected
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  property("Delete (wrong user)") = Prop.forAll(
    creationSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexFoodService = complexFoodServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(Seq(setup.complexFoodIncoming)),
      complexIngredientContents = Seq.empty
    )
    val transformer = for {
      result <- EitherT.liftF(complexFoodService.delete(userId2, setup.recipe.id))
      fetched <- EitherT.fromOptionF(
        complexFoodService.get(setup.userId, setup.complexFoodIncoming.recipeId),
        ErrorContext.ComplexFood.NotFound.asServerError
      )
    } yield {
      val expected = toComplexFood(setup.complexFoodIncoming, setup.recipe)
      Prop.all(
        !result,
        fetched ?= expected
      )
    }

    DBTestUtil.awaitProp(transformer)
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests.withoutDB)

}
