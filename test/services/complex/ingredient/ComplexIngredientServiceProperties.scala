package services.complex.ingredient

import cats.data.EitherT
import cats.implicits.catsSyntaxTuple2Semigroupal
import db._
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties, Test }
import services.complex.food.ComplexFoodIncoming
import services.recipe.Recipe
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import GenUtils.implicits._
import config.TestConfiguration

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

  private val asComplexFoodGen: Gen[(Recipe, ComplexFoodIncoming)] = for {
    recipe      <- services.recipe.Gens.recipeGen
    complexFood <- services.complex.food.Gens.complexFood(recipe.id)
  } yield recipe -> complexFood

  private val setupBaseGen: Gen[SetupBase] = for {
    userId                <- GenUtils.taggedId[UserTag]
    recipe                <- services.recipe.Gens.recipeGen
    recipesAsComplexFoods <- Gen.nonEmptyListOf(asComplexFoodGen)
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

  private case class CreateSetup(
      base: SetupBase,
      complexIngredient: ComplexIngredient
  )

  private val createSetupGen: Gen[CreateSetup] = for {
    base              <- setupBaseGen
    complexIngredient <- Gens.complexIngredientGen(base.recipe.id, base.recipesAsComplexFoods.map(_._1.id))
  } yield CreateSetup(
    base = base,
    complexIngredient = complexIngredient
  )

  property("Create (success)") = Prop.forAll(createSetupGen :| "setup") { setup =>
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

  property("Create (failure, exists)") = Prop.forAll(createSetupGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, Seq(setup.complexIngredient))
    )
    val propF = for {
      created <- complexIngredientService.create(
        setup.base.userId,
        // Only the factor is flexible, hence a different number is used for distinction.
        setup.complexIngredient.copy(factor = setup.complexIngredient.factor + 1)
      )
      fetched <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
    } yield {
      Prop.all(
        created.isLeft,
        fetched ?= Seq(setup.complexIngredient)
      )
    }

    DBTestUtil.await(propF)
  }

// TODO #61: Use this as a base for a proper DB cycle check test.
//
//  private case class CycleSetup(
//      base: SetupBase,
//      recipes: Seq[Recipe],
//      complexFoods: Seq[ComplexFoodIncoming],
//      chainEnd: ComplexIngredient,
//      chain: Seq[ComplexIngredient]
//  )
//
//  private val cycleSetupGen: Gen[CycleSetup] = for {
//    base           <- setupBaseGen
//    innerChainSize <- Gen.choose(0, 20)
//    chainSize = 2 + innerChainSize
//    factors <- Gen.listOfN(chainSize, GenUtils.smallBigDecimalGen)
//    recipes = base.recipesAsComplexFoods.map(_._1)
//    complexFoods <- recipes.traverse { recipe => services.complex.food.Gens.complexFood(recipe.id) }
//  } yield {
//    val chain = recipes.zip(recipes.tail).zip(factors).map {
//      case ((r1, r2), factor) =>
//        ComplexIngredient(
//          recipeId = r1.id,
//          complexFoodId = r2.id,
//          factor = factor
//        )
//    }
//    val chainEnd = ComplexIngredient(
//      recipeId = recipes.last.id,
//      complexFoodId = recipes.head.id,
//      factor = factors.last
//    )
//    CycleSetup(
//      base = base,
//      recipes,
//      complexFoods,
//      chainEnd = chainEnd,
//      chain = chain
//    )
//  }
//
//  property("Create (failure, cycle)") = Prop.forAll(cycleSetupGen :| "setup") { setup =>
//    val complexIngredientService = complexIngredientServiceWith(
//      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, setup.base.recipe +: setup.recipes),
//      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
//      complexIngredientContents = ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, setup.chain)
//    )
//    val propF = for {
//      created <- complexIngredientService.create(setup.base.userId, setup.chainEnd)
//      fetched <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
//    } yield {
//      Prop.all(
//        created.left.map(_.message) ?= Left(
//          ErrorContext.Recipe.ComplexIngredient.Creation(DBError.Complex.Ingredient.Cycle.getMessage).message
//        ),
//        fetched ?= setup.chain
//      )
//    }
//
//    DBTestUtil.await(propF)
//  }

  private case class UpdateSetup(
      base: SetupBase,
      complexIngredient: ComplexIngredient,
      update: ComplexIngredient
  )

  private val updateSetupGen: Gen[UpdateSetup] = for {
    base              <- setupBaseGen
    complexIngredient <- Gens.complexIngredientGen(base.recipe.id, base.recipesAsComplexFoods.map(_._1.id))
    update            <- Gens.complexIngredientGen(complexIngredient.recipeId, Seq(complexIngredient.complexFoodId))
  } yield UpdateSetup(
    base,
    complexIngredient,
    update
  )

  property("Update (success)") = Prop.forAll(updateSetupGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, Seq(setup.complexIngredient))
    )
    val transformer = for {
      updated <- EitherT(complexIngredientService.update(setup.base.userId, setup.update))
      fetched <- EitherT.liftF[Future, ServerError, Seq[ComplexIngredient]](
        complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
      )
    } yield Prop.all(
      updated ?= setup.update,
      fetched ?= Seq(setup.update)
    )

    DBTestUtil.awaitProp(transformer)
  }

  private val updateFailureSetupGen: Gen[UpdateSetup] = for {
    base              <- setupBaseGen
    complexIngredient <- Gens.complexIngredientGen(base.recipe.id, base.recipesAsComplexFoods.map(_._1.id))
    other             <- asComplexFoodGen
    update            <- Gens.complexIngredientGen(complexIngredient.recipeId, Seq(other._1.id))
  } yield UpdateSetup(
    base.copy(
      recipesAsComplexFoods = base.recipesAsComplexFoods :+ other
    ),
    complexIngredient,
    update
  )

  property("Update (failure)") = Prop.forAll(updateFailureSetupGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, Seq(setup.complexIngredient))
    )

    val propF = for {
      result  <- complexIngredientService.update(setup.base.userId, setup.update)
      fetched <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
    } yield Prop.all(
      result.isLeft,
      fetched ?= Seq(setup.complexIngredient)
    )

    DBTestUtil.await(propF)
  }

  property("Delete (existent)") = Prop.forAll(createSetupGen :| "setup") { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, Seq(setup.complexIngredient))
    )
    val propF = for {
      deleted <-
        complexIngredientService.delete(setup.base.userId, setup.base.recipe.id, setup.complexIngredient.complexFoodId)
      fetched <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
    } yield Prop.all(
      deleted,
      fetched ?= Seq.empty
    )
    DBTestUtil.await(propF)
  }

  private case class OtherKey(
      recipeId: RecipeId,
      complexFoodId: ComplexFoodId
  )

  private case class DeleteFailureSetup(
      existing: CreateSetup,
      otherKey: OtherKey
  )

  private def otherKeyGen(recipeId: RecipeId, complexFoodId: ComplexFoodId): Gen[OtherKey] = {
    val fixedRecipeGen      = Gen.const(recipeId)
    val anyRecipeGen        = GenUtils.taggedId[RecipeTag]
    val fixedComplexFoodGen = Gen.const(complexFoodId)
    val anyComplexFoodGen   = GenUtils.taggedId[RecipeTag]
    Gen
      .oneOf(
        List(
          (fixedComplexFoodGen, anyRecipeGen),
          (anyComplexFoodGen, fixedRecipeGen),
          (anyComplexFoodGen, anyRecipeGen)
        ).map(_.mapN(OtherKey))
      )
      .flatMap(identity)
  }

  private val deleteFailureSetupGen: Gen[DeleteFailureSetup] = for {
    existing <- createSetupGen
    otherKey <- otherKeyGen(existing.base.recipe.id, existing.complexIngredient.complexFoodId)
  } yield DeleteFailureSetup(
    existing = existing,
    otherKey = otherKey
  )

  property("Delete (non-existent)") = Prop.forAll(
    deleteFailureSetupGen :| "setup"
  ) { setup =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.existing.base.userId, Seq(setup.existing.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.existing.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.existing.base.recipe.id, Seq(setup.existing.complexIngredient))
    )
    val propF = for {
      deleted <- complexIngredientService.delete(
        setup.existing.base.userId,
        setup.otherKey.recipeId,
        setup.otherKey.complexFoodId
      )
      fetched <- complexIngredientService.all(setup.existing.base.userId, setup.existing.base.recipe.id)
    } yield Prop.all(
      !deleted,
      fetched ?= Seq(setup.existing.complexIngredient)
    )

    DBTestUtil.await(propF)
  }

  property("Fetch all (wrong user)") = Prop.forAll(
    fetchAllSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents = ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, setup.complexIngredients)
    )
    val propF = for {
      fetched <- complexIngredientService.all(userId2, setup.base.recipe.id)
    } yield fetched ?= Seq.empty
    DBTestUtil.await(propF)
  }

  property("Create (wrong user)") = Prop.forAll(
    createSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents = Seq.empty
    )
    val propF = for {
      created <- complexIngredientService.create(userId2, setup.complexIngredient)
      fetched <- complexIngredientService.all(userId2, setup.base.recipe.id)
    } yield {
      Prop.all(
        created.isLeft,
        fetched ?= Seq.empty
      )
    }

    DBTestUtil.await(propF)
  }
  property("Update (wrong user)") = Prop.forAll(
    updateSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, Seq(setup.complexIngredient))
    )
    val propF = for {
      updated  <- complexIngredientService.update(userId2, setup.update)
      fetched1 <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
      fetched2 <- complexIngredientService.all(userId2, setup.base.recipe.id)
    } yield Prop.all(
      updated.isLeft,
      fetched1 ?= Seq(setup.complexIngredient),
      fetched2 ?= Seq.empty
    )

    DBTestUtil.await(propF)
  }

  property("Delete (wrong user)") = Prop.forAll(
    createSetupGen :| "setup",
    GenUtils.taggedId[UserTag] :| "userId2"
  ) { (setup, userId2) =>
    val complexIngredientService = complexIngredientServiceWith(
      recipeContents = ContentsUtil.Recipe.from(setup.base.userId, Seq(setup.base.recipe)),
      complexFoodContents = ContentsUtil.ComplexFood.from(setup.base.recipesAsComplexFoods.map(_._2)),
      complexIngredientContents =
        ContentsUtil.ComplexIngredient.from(setup.base.recipe.id, Seq(setup.complexIngredient))
    )
    val propF = for {
      deleted <- complexIngredientService.delete(userId2, setup.base.recipe.id, setup.complexIngredient.complexFoodId)
      fetched <- complexIngredientService.all(setup.base.userId, setup.base.recipe.id)
    } yield Prop.all(
      !deleted,
      fetched ?= Seq(setup.complexIngredient)
    )
    DBTestUtil.await(propF)
  }

  override def overrideParameters(p: Test.Parameters): Test.Parameters =
    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests.withoutDB)

}
