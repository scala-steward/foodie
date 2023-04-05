package services.duplication.recipe

import cats.data.EitherT
import cats.syntax.traverse._
import db._
import errors.ServerError
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.GenUtils.implicits._
import services.complex.food.ComplexFoodIncoming
import services.complex.ingredient.{ ComplexIngredient, ComplexIngredientServiceProperties }
import services.recipe.{ AmountUnit, FullRecipe, Ingredient, Recipe, RecipeServiceProperties }
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object RecipeDuplicationProperties extends Properties("Recipe duplication") {

  def companionWith(
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(RecipeId, Ingredient)],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): services.duplication.recipe.Live.Companion =
    new services.duplication.recipe.Live.Companion(
      recipeServiceCompanion = RecipeServiceProperties.companionWith(
        recipeContents = recipeContents,
        ingredientContents = ingredientContents
      ),
      ingredientDao = DAOTestInstance.Ingredient.instanceFrom(ingredientContents),
      complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(complexIngredientContents)
    )

  def duplicationWith(
      recipeContents: Seq[(UserId, Recipe)],
      ingredientContents: Seq[(RecipeId, Ingredient)],
      complexFoods: Seq[ComplexFoodIncoming],
      complexIngredientContents: Seq[(RecipeId, ComplexIngredient)]
  ): Duplication =
    new services.duplication.recipe.Live(
      dbConfigProvider = TestUtil.databaseConfigProvider,
      companion = companionWith(
        recipeContents = recipeContents,
        ingredientContents = ingredientContents,
        complexIngredientContents = complexIngredientContents
      ),
      recipeServiceCompanion = RecipeServiceProperties.companionWith(
        recipeContents = recipeContents,
        ingredientContents = ingredientContents
      ),
      complexIngredientServiceCompanion = ComplexIngredientServiceProperties.companionWith(
        recipeContents = recipeContents,
        complexFoodContents = ContentsUtil.ComplexFood.from(complexFoods),
        complexIngredientContents = complexIngredientContents
      )
    )

  private case class DuplicationSetup(
      userId: UserId,
      recipe: Recipe,
      referencedRecipes: List[Recipe],
      complexFoods: List[ComplexFoodIncoming],
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient]
  )

  private val duplicationSetupGen: Gen[DuplicationSetup] = for {
    userId                <- GenUtils.taggedId[UserTag]
    recipe                <- services.recipe.Gens.recipeGen
    referencedRecipes     <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    subsetForComplexFoods <- GenUtils.subset(referencedRecipes).map(_.map(_.id))
    complexFoods          <- subsetForComplexFoods.traverse(services.complex.food.Gens.complexFood)
    ingredients           <- Gen.listOf(services.recipe.Gens.ingredientGen)
    complexIngredients <- services.complex.ingredient.Gens
      .complexIngredientsGen(recipe.id, complexFoods.map(_.recipeId))
  } yield DuplicationSetup(
    userId = userId,
    recipe = recipe,
    referencedRecipes = referencedRecipes,
    complexFoods = complexFoods,
    ingredients = ingredients,
    complexIngredients = complexIngredients
  )

  private case class IngredientValues(
      foodId: FoodId,
      amountUnit: AmountUnit
  )

  private def groupIngredients(ingredients: Seq[Ingredient]): Map[(FoodId, Option[MeasureId]), List[IngredientValues]] =
    ingredients
      .groupBy(ingredient => (ingredient.foodId, ingredient.amountUnit.measureId))
      .view
      .mapValues(
        _.sortBy(_.amountUnit.factor)
          .map(ingredient => IngredientValues(ingredient.foodId, ingredient.amountUnit))
          .toList
      )
      .toMap

  propertyWithSeed("Duplication produces expected result", Some("guxVnmZph0PvL42sjuJ_ki16cNc5775N46C-21r2ohL=")) =
    Prop.forAll(duplicationSetupGen :| "setup") { setup =>
      val fullRecipe = FullRecipe(
        recipe = setup.recipe,
        ingredients = setup.ingredients
      )
      val recipeDao = DAOTestInstance.Recipe.instanceFrom(ContentsUtil.Recipe.from(setup.userId, Seq(setup.recipe)))
      val complexFoodDao = DAOTestInstance.ComplexFood.instanceFrom(ContentsUtil.ComplexFood.from(setup.complexFoods))
      val ingredientDao  = DAOTestInstance.Ingredient.instanceFrom(ContentsUtil.Ingredient.from(fullRecipe))
      val complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(
        ContentsUtil.ComplexIngredient.from(setup.recipe.id, setup.complexIngredients)
      )

      val recipeServiceCompanion = new services.recipe.Live.Companion(
        recipeDao = recipeDao,
        ingredientDao = ingredientDao,
        generalTableConstants = DBTestUtil.generalTableConstants
      )
      val complexIngredientServiceCompanion = new services.complex.ingredient.Live.Companion(
        recipeDao = recipeDao,
        complexFoodDao = complexFoodDao,
        complexIngredientDao = complexIngredientDao
      )

      val recipeService = new services.recipe.Live(
        TestUtil.databaseConfigProvider,
        recipeServiceCompanion
      )
      val complexIngredientService = new services.complex.ingredient.Live(
        TestUtil.databaseConfigProvider,
        complexIngredientServiceCompanion
      )
      val duplication =
        new services.duplication.recipe.Live(
          TestUtil.databaseConfigProvider,
          new Live.Companion(
            recipeServiceCompanion,
            ingredientDao,
            complexIngredientDao
          ),
          recipeServiceCompanion = recipeServiceCompanion,
          complexIngredientServiceCompanion = complexIngredientServiceCompanion
        )

      val transformer = for {
        duplicatedRecipe <- EitherT(duplication.duplicate(setup.userId, setup.recipe.id))
        ingredients <- EitherT.liftF[Future, ServerError, List[Ingredient]](
          recipeService.getIngredients(setup.userId, duplicatedRecipe.id)
        )
        complexIngredients <- EitherT.liftF[Future, ServerError, Seq[ComplexIngredient]](
          complexIngredientService.all(setup.userId, duplicatedRecipe.id)
        )
      } yield {
        Prop.all(
          groupIngredients(ingredients) ?= groupIngredients(setup.ingredients),
          complexIngredients.sortBy(_.complexFoodId).map(_.copy(recipeId = setup.recipe.id)) ?= setup.complexIngredients
            .sortBy(_.complexFoodId),
          duplicatedRecipe.name.startsWith(setup.recipe.name),
          duplicatedRecipe.description ?= setup.recipe.description,
          duplicatedRecipe.numberOfServings ?= setup.recipe.numberOfServings,
          duplicatedRecipe.servingSize ?= setup.recipe.servingSize
        )
      }

      DBTestUtil.awaitProp(transformer)
    }
}
