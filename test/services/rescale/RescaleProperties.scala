package services.rescale

import cats.data.EitherT
import cats.syntax.traverse._
import db.{ DAOTestInstance, UserId, UserTag }
import errors.ErrorContext
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.{ Gen, Prop, Properties }
import services.GenUtils.implicits._
import services.complex.food.{ ComplexFoodIncoming, ComplexFoodServiceProperties }
import services.complex.ingredient.{ ComplexIngredient, ComplexIngredientService }
import services.nutrient.NutrientService
import services.recipe.{ FullRecipe, Ingredient, Recipe, RecipeService }
import services.stats.StatsService
import services.{ ContentsUtil, DBTestUtil, GenUtils, TestUtil }
import util.PropUtil

import scala.concurrent.ExecutionContext.Implicits.global

object RescaleProperties extends Properties("Rescale properties") {

  private val nutrientServiceCompanion = TestUtil.injector.instanceOf[NutrientService.Companion]

  case class Services(
      recipeService: RecipeService,
      complexIngredientService: ComplexIngredientService,
      rescaleService: RescaleService,
      statsService: StatsService
  )

  def servicesWith(
      userId: UserId,
      complexFoods: List[ComplexFoodIncoming],
      recipe: Recipe,
      referencedRecipes: List[Recipe],
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient]
  ): Services = {
    val recipeDao = DAOTestInstance.Recipe.instanceFrom(ContentsUtil.Recipe.from(userId, recipe +: referencedRecipes))
    val complexFoodDao = DAOTestInstance.ComplexFood.instanceFrom(ContentsUtil.ComplexFood.from(complexFoods))
    val ingredientDao = DAOTestInstance.Ingredient.instanceFrom(
      ContentsUtil.Ingredient.from(
        FullRecipe(
          recipe = recipe,
          ingredients = ingredients
        )
      )
    )
    val complexIngredientDao = DAOTestInstance.ComplexIngredient.instanceFrom(
      ContentsUtil.ComplexIngredient.from(recipe.id, complexIngredients)
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

    val statsServiceCompanion = new services.stats.Live.Companion(
      mealService = new services.meal.Live.Companion(
        mealDao = DAOTestInstance.Meal.instanceFrom(Seq.empty),
        mealEntryDao = DAOTestInstance.MealEntry.instanceFrom(Seq.empty)
      ),
      recipeService = recipeServiceCompanion,
      nutrientService = nutrientServiceCompanion,
      complexFoodService = ComplexFoodServiceProperties.companionWith(
        recipeContents = ContentsUtil.Recipe.from(userId, referencedRecipes),
        complexFoodContents = ContentsUtil.ComplexFood.from(complexFoods)
      ),
      complexIngredientService = complexIngredientServiceCompanion
    )

    Services(
      recipeService = new services.recipe.Live(
        TestUtil.databaseConfigProvider,
        recipeServiceCompanion
      ),
      complexIngredientService = new services.complex.ingredient.Live(
        TestUtil.databaseConfigProvider,
        complexIngredientServiceCompanion
      ),
      rescaleService = new services.rescale.Live(
        TestUtil.databaseConfigProvider,
        new services.rescale.Live.Companion(
          recipeServiceCompanion,
          statsServiceCompanion
        )
      ),
      statsService = new services.stats.Live(
        TestUtil.databaseConfigProvider,
        statsServiceCompanion
      )
    )
  }

  private case class RescaleSetup(
      userId: UserId,
      recipe: Recipe,
      referencedRecipes: List[Recipe],
      complexFoods: List[ComplexFoodIncoming],
      ingredients: List[Ingredient],
      complexIngredients: List[ComplexIngredient],
      servingSizeInGrams: BigDecimal
  )

  private val rescaleSetupGen: Gen[RescaleSetup] = for {
    userId                <- GenUtils.taggedId[UserTag]
    recipe                <- services.recipe.Gens.recipeGen
    referencedRecipes     <- Gen.nonEmptyListOf(services.recipe.Gens.recipeGen)
    subsetForComplexFoods <- GenUtils.subset(referencedRecipes).map(_.map(_.id))
    complexFoods          <- subsetForComplexFoods.traverse(services.complex.food.Gens.complexFood)
    ingredients           <- Gen.listOf(services.recipe.Gens.ingredientGen)
    complexIngredients <- services.complex.ingredient.Gens
      .complexIngredientsGen(recipe.id, complexFoods.map(_.recipeId))
    servingSize <- GenUtils.smallBigDecimalGen
    spaces      <- Gen.choose(0, 10)
  } yield RescaleSetup(
    userId = userId,
    recipe = recipe.copy(
      servingSize = Some(s"$servingSize${List.fill(spaces)(" ").mkString}g")
    ),
    referencedRecipes = referencedRecipes,
    complexFoods,
    ingredients = ingredients,
    complexIngredients = complexIngredients,
    servingSizeInGrams = servingSize
  )

  property("Rescaling produces expected result") = Prop.forAll(rescaleSetupGen :| "setup") { setup =>
    val services = servicesWith(
      userId = setup.userId,
      complexFoods = setup.complexFoods,
      recipe = setup.recipe,
      referencedRecipes = setup.referencedRecipes,
      ingredients = setup.ingredients,
      complexIngredients = setup.complexIngredients
    )
    val transformer = for {
      rescaledRecipe <- EitherT(services.rescaleService.rescale(setup.userId, setup.recipe.id))
      recipeWeight <- EitherT.fromOptionF(
        services.statsService.weightOfRecipe(setup.userId, setup.recipe.id),
        ErrorContext.Recipe.NotFound.asServerError
      )
    } yield Prop.all(
      rescaledRecipe.copy(numberOfServings = setup.recipe.numberOfServings) ?= setup.recipe,
      PropUtil.closeEnough(Some(rescaledRecipe.numberOfServings * setup.servingSizeInGrams), Some(recipeWeight))
    )

    DBTestUtil.awaitProp(transformer)
  }

}
