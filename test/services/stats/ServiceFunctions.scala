package services.stats

import cats.data.{ EitherT, OptionT }
import cats.syntax.traverse._
import db.generated.Tables
import errors.ServerError
import io.scalaland.chimney.dsl._
import services._
import services.meal.{ Meal, MealEntry, MealEntryPreCreation, MealParameters, MealService }
import services.recipe.{ Ingredient, IngredientPreCreation, Recipe, RecipeParameters, RecipeService }
import services.user.User
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ServiceFunctions {

  def computeNutrientAmount(
      nutrientId: NutrientId,
      ingredients: Seq[Ingredient]
  ): DBIO[Option[(Int, BigDecimal)]] = {
    val transformer =
      for {
        conversionFactors <-
          ingredients
            .traverse { ingredient =>
              OptionT
                .fromOption[DBIO](ingredient.amountUnit.measureId)
                .subflatMap(measureId => GenUtils.allConversionFactors.get((ingredient.foodId, measureId)))
                .orElseF(DBIO.successful(Some(BigDecimal(1))))
                .map(ingredient.id -> _)
            }
            .map(_.toMap)
        nutrientAmounts <- OptionT.liftF(nutrientAmountOf(nutrientId, ingredients.map(_.foodId)))
        ingredientAmounts = ingredients.flatMap { ingredient =>
          nutrientAmounts.get(ingredient.foodId).map { nutrientAmount =>
            nutrientAmount *
              ingredient.amountUnit.factor *
              conversionFactors(ingredient.id)
          }
        }
        amounts <- OptionT.fromOption[DBIO](Some(ingredientAmounts).filter(_.nonEmpty))
      } yield (nutrientAmounts.keySet.size, amounts.sum)

    transformer.value
  }

  def nutrientAmountOf(
      nutrientId: NutrientId,
      foodIds: Seq[FoodId]
  ): DBIO[Map[FoodId, BigDecimal]] = {
    val baseMap = Tables.NutrientAmount
      .filter(na =>
        na.nutrientId === nutrientId.transformInto[Int]
          && na.foodId.inSetBind(foodIds.map(_.transformInto[Int]))
      )
      .result
      .map { nutrientAmounts =>
        nutrientAmounts
          .map(na => na.foodId.transformInto[FoodId] -> na.nutrientValue)
          .toMap
      }
    /* The constellation of foodId = 534 and nutrientId = 339 has no entry in the
       amount table, but there is an entry referencing the non-existing nutrientId = 328,
       with the value 0.1.
       There is no nutrient with id 328, but there is one nutrient with the *code* 328,
       and this nutrient has the id 339.
       The assumption is that this reference has been added by mistake,
       hence we correct this mistake here.
     */
    val erroneousNutrientId = 339.transformInto[NutrientId]
    val erroneousFoodId     = 534.transformInto[FoodId]
    if (nutrientId == erroneousNutrientId && foodIds.contains(erroneousFoodId)) {
      baseMap.map(_.updated(erroneousFoodId, BigDecimal(0.1)))
    } else {
      baseMap
    }
  }

  case class FullRecipe(
      recipe: Recipe,
      ingredients: List[Ingredient]
  )

  def computeNutrientAmounts(
      fullRecipe: FullRecipe
  ): Future[Map[NutrientId, Option[(Int, BigDecimal)]]] = {
    DBTestUtil.dbRun {
      GenUtils.allNutrients
        .traverse { nutrient =>
          computeNutrientAmount(nutrient.id, fullRecipe.ingredients)
            .map(v =>
              nutrient.id ->
                v.map { case (number, value) => number -> value / fullRecipe.recipe.numberOfServings }
            ): DBIO[(NutrientId, Option[(Int, BigDecimal)])]
        }
        .map(_.toMap)
    }
  }

  def createRecipe(recipeService: RecipeService)(
      userId: UserId,
      recipeParameters: RecipeParameters
  ): EitherT[Future, ServerError, FullRecipe] =
    for {
      recipe <- EitherT(recipeService.createRecipe(userId, recipeParameters.recipeCreation))
      ingredients <- recipeParameters.ingredientParameters.traverse(ip =>
        EitherT(
          recipeService.addIngredient(
            userId = userId,
            ingredientCreation = IngredientPreCreation.toCreation(recipe.id, ip.ingredientPreCreation)
          )
        )
      )
    } yield FullRecipe(recipe, ingredients)

  case class FullMeal(
      meal: Meal,
      mealEntries: List[MealEntry]
  )

  def createMeal(
      mealService: MealService
  )(
      user: User,
      mealParameters: MealParameters
  ): EitherT[Future, ServerError, FullMeal] =
    for {
      meal <- EitherT(mealService.createMeal(user.id, mealParameters.mealCreation))
      mealEntries <- mealParameters.mealEntryParameters.traverse(mep =>
        EitherT(
          mealService.addMealEntry(
            userId = user.id,
            mealEntryCreation = MealEntryPreCreation.toCreation(meal.id, mep.mealEntryPreCreation)
          )
        )
      )
    } yield FullMeal(
      meal = meal,
      mealEntries = mealEntries
    )

}
