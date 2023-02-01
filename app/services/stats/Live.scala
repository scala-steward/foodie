package services.stats

import algebra.ring.AdditiveMonoid
import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.complex.food.ComplexFoodService
import services.complex.ingredient.ComplexIngredientService
import services.meal.{ MealEntry, MealService }
import services.nutrient.{ AmountEvaluation, Nutrient, NutrientMap, NutrientService }
import services.recipe.{ AmountUnit, RecipeService }
import db._
import services.common.RequestInterval
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.implicits._
import spire.math.Natural
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.collection.MapUtil

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: StatsService.Companion
)(implicit
    ec: ExecutionContext
) extends StatsService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats] =
    db.run(companion.nutrientsOverTime(userId, requestInterval))

  override def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountMap]] =
    db.run(companion.nutrientsOfFood(foodId))

  override def nutrientsOfComplexFood(
      userId: UserId,
      complexFoodId: ComplexFoodId
  ): Future[Option[NutrientAmountMap]] =
    db.run(companion.nutrientsOfComplexFood(userId, complexFoodId))

  override def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountMap]] =
    db.run(companion.nutrientsOfRecipe(userId, recipeId))

  override def nutrientsOfMeal(userId: UserId, mealId: MealId): Future[NutrientAmountMap] =
    db.run(companion.nutrientsOfMeal(userId, mealId))

  override def weightOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[BigDecimal]] =
    db.run(companion.weightOfRecipe(userId, recipeId))

  override def weightOfMeal(userId: UserId, mealId: MealId): Future[Option[BigDecimal]] =
    db.run(companion.weightOfMeal(userId, mealId))

  override def weightOfMeals(userId: UserId, mealIds: Seq[MealId]): Future[BigDecimal] =
    db.run(companion.weightOfMeals(userId, mealIds))

}

object Live {

  class Companion @Inject() (
      mealService: MealService.Companion,
      recipeService: RecipeService.Companion,
      nutrientService: NutrientService.Companion,
      complexFoodService: ComplexFoodService.Companion,
      complexIngredientService: ComplexIngredientService.Companion
  ) extends StatsService.Companion {

    override def nutrientsOverTime(
        userId: UserId,
        requestInterval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Stats] = {
      for {
        meals <- mealService.allMeals(userId, requestInterval)
        mealIds = meals.map(_.id)
        meals              <- mealIds.traverse(mealService.getMeal(userId, _)).map(_.flatten)
        mealEntries        <- mealIds.flatTraverse(mealService.getMealEntries(userId, _))
        nutrientsPerRecipe <- nutrientsOfRecipeIds(userId, mealEntries.map(_.recipeId))
        allNutrients       <- nutrientService.all
      } yield {
        val nutrientAmountMap =
          nutrientAmountMapOfMealEntries(mealEntries, nutrientsPerRecipe, allNutrients)
        Stats(
          meals = meals,
          nutrientAmountMap = nutrientAmountMap
        )
      }
    }

    override def nutrientsOfFood(foodId: FoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        _ <- OptionT(
          Tables.FoodName
            .filter(_.foodId === foodId.transformInto[Int])
            .result
            .headOption: DBIO[Option[Tables.FoodNameRow]]
        )
        nutrientMap  <- OptionT.liftF(nutrientService.nutrientsOfFood(foodId, None, BigDecimal(1)))
        allNutrients <- OptionT.liftF(nutrientService.all)
      } yield unifyAndCount(
        nutrientMap = nutrientMap,
        totalNumberOfIngredients = 1,
        allNutrients = allNutrients
      )

      transformer.value
    }

    override def nutrientsOfComplexFood(userId: UserId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        complexFood <- OptionT(complexFoodService.get(userId, complexFoodId))
        recipeStats <- OptionT(nutrientsOfRecipeWith(userId, complexFoodId, ScaleMode.Unit(complexFood.amountGrams)))
      } yield recipeStats

      transformer.value
    }

    override def nutrientsOfRecipe(
        userId: UserId,
        recipeId: RecipeId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] =
      nutrientsOfRecipeWith(userId, recipeId, ScaleMode.Serving)

    private def nutrientsOfRecipeWith(
        userId: UserId,
        recipeId: RecipeId,
        scaleMode: ScaleMode
    )(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        allNutrients      <- OptionT.liftF(nutrientService.all)
        recipeNutrientMap <- nutrientsOfRecipeT(userId, recipeId, scaleMode)
      } yield unifyAndCount(
        recipeNutrientMap.nutrientMap,
        totalNumberOfIngredients = recipeNutrientMap.foodIds.size,
        allNutrients = allNutrients
      )

      transformer.value
    }

    override def nutrientsOfMeal(
        userId: UserId,
        mealId: MealId
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientAmountMap] =
      for {
        mealEntries        <- mealService.getMealEntries(userId, mealId)
        nutrientsPerRecipe <- nutrientsOfRecipeIds(userId, mealEntries.map(_.recipeId))
        allNutrients       <- nutrientService.all
      } yield nutrientAmountMapOfMealEntries(mealEntries, nutrientsPerRecipe, allNutrients)

    override def weightOfRecipe(userId: UserId, recipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]] = {
      val transformer = for {
        _           <- OptionT(recipeService.getRecipe(userId, recipeId))
        ingredients <- OptionT.liftF(recipeService.getIngredients(userId, recipeId))
        ingredientWeights <- OptionT.liftF {
          ingredients.traverse { ingredient =>
            nutrientService
              .conversionFactor(ingredient.foodId, ingredient.amountUnit.measureId.getOrElse(AmountUnit.hundredGrams))
              .map { conversionFactor =>
                100 * ingredient.amountUnit.factor * conversionFactor.conversionFactorValue
              }: DBIO[BigDecimal]
          }
        }
        complexIngredients <- OptionT.liftF(complexIngredientService.all(userId, recipeId))
        // Since 'traverse' is involved, this is quite slow.
        complexIngredientsWeights <- complexIngredients.traverse { complexIngredient =>
          OptionT(complexFoodService.get(userId, complexIngredient.complexFoodId))
            .map { complexFood =>
              complexIngredient.factor * complexFood.amountGrams
            }
        }
      } yield ingredientWeights.sum + complexIngredientsWeights.sum

      transformer.value
    }

    override def weightOfMeal(userId: UserId, mealId: MealId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[BigDecimal]] = {
      val transformer = for {
        mealEntries <- OptionT.liftF(mealService.getMealEntries(userId, mealId))
        // Warning: Nested 'traverse' - the performance may be lacking.
        weights <- mealEntries.traverse { mealEntry =>
          for {
            recipe <- OptionT(recipeService.getRecipe(userId, mealEntry.recipeId))
            weight <- OptionT(weightOfRecipe(userId, mealEntry.recipeId))
          } yield mealEntry.numberOfServings * weight / recipe.numberOfServings
        }
      } yield weights.sum

      transformer.value
    }

    override def weightOfMeals(userId: UserId, mealIds: Seq[MealId])(implicit ec: ExecutionContext): DBIO[BigDecimal] =
      mealIds
      // Doubly nested 'traverse' - this is likely to scale very poorly.
        .traverse { mealId =>
          OptionT(weightOfMeal(userId, mealId))
        }
        .map(_.sum)
        .getOrElse(BigDecimal(0))

    private def nutrientsOfRecipeIds(
        userId: UserId,
        recipeIds: Seq[RecipeId]
    )(implicit ec: ExecutionContext): DBIO[Map[RecipeId, RecipeNutrientMap]] =
      recipeIds.distinct
        .traverse { recipeId =>
          nutrientsOfRecipeT(userId, recipeId, ScaleMode.Serving)
            .map(recipeId -> _)
            .value
        }
        .map(_.flatten.toMap)

    private def nutrientsOfRecipeT(
        userId: UserId,
        recipeId: RecipeId,
        scaleMode: ScaleMode
    )(implicit
        ec: ExecutionContext
    ): OptionT[DBIO, RecipeNutrientMap] = {
      case class NutrientsAndFoods(
          nutrientMap: NutrientMap,
          foodIds: Set[FoodId]
      )

      def descend(recipeId: RecipeId): DBIO[NutrientsAndFoods] =
        for {
          ingredients        <- recipeService.getIngredients(userId, recipeId)
          complexIngredients <- complexIngredientService.all(userId, recipeId)
          nutrients          <- nutrientService.nutrientsOfIngredients(ingredients)
          recipeNutrientMapsOfComplexNutrients <-
            complexIngredients
              .traverse { complexIngredient =>
                descend(complexIngredient.complexFoodId)
                  .map(recipeNutrientMap =>
                    recipeNutrientMap.copy(nutrientMap = complexIngredient.factor *: recipeNutrientMap.nutrientMap)
                  ): DBIO[NutrientsAndFoods]
              }
        } yield NutrientsAndFoods(
          nutrientMap = nutrients + recipeNutrientMapsOfComplexNutrients.map(_.nutrientMap).qsum,
          foodIds = ingredients.map(_.foodId).toSet ++ recipeNutrientMapsOfComplexNutrients.flatMap(_.foodIds)
        )

      for {
        recipe            <- OptionT(recipeService.getRecipe(userId, recipeId))
        nutrientsAndFoods <- OptionT.liftF(descend(recipeId))
      } yield {
        val scale = scaleMode match {
          case ScaleMode.Serving             => recipe.numberOfServings.reciprocal
          case ScaleMode.Unit(definedAmount) => BigDecimal(100) / definedAmount
        }
        RecipeNutrientMap(
          recipe = recipe,
          nutrientMap = scale *: nutrientsAndFoods.nutrientMap,
          foodIds = nutrientsAndFoods.foodIds
        )
      }
    }

    private sealed trait ScaleMode

    private object ScaleMode {
      case object Serving extends ScaleMode

      case class Unit(definedAmount: BigDecimal) extends ScaleMode
    }

    private def nutrientAmountMapOfMealEntries(
        mealEntries: Seq[MealEntry],
        nutrientsPerRecipe: Map[RecipeId, RecipeNutrientMap],
        allNutrients: Seq[Nutrient]
    ): NutrientAmountMap = {
      val nutrientMap = mealEntries.map { mealEntry =>
        mealEntry.numberOfServings *: nutrientsPerRecipe(mealEntry.recipeId).nutrientMap
      }.qsum
      val totalNumberOfIngredients = nutrientsPerRecipe.values.flatMap(_.foodIds).toSet.size

      unifyAndCount(
        nutrientMap = nutrientMap,
        totalNumberOfIngredients = totalNumberOfIngredients,
        allNutrients = allNutrients
      )
    }

    private def unifyAndCount(
        nutrientMap: NutrientMap,
        totalNumberOfIngredients: Int,
        allNutrients: Seq[Nutrient]
    ): NutrientAmountMap = {
      MapUtil
        .unionWith(
          nutrientMap,
          allNutrients.map(n => n -> AdditiveMonoid[AmountEvaluation].zero).toMap
        )((x, _) => x)
        .view
        .mapValues(amountEvaluation =>
          Amount(
            value = Some(amountEvaluation.amount).filter(_ => amountEvaluation.encounteredFoodIds.nonEmpty),
            numberOfIngredients = Natural(totalNumberOfIngredients),
            numberOfDefinedValues = Natural(amountEvaluation.encounteredFoodIds.size)
          )
        )
        .toMap
    }

  }

}
