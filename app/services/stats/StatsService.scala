package services.stats

import algebra.ring.AdditiveMonoid
import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.complex.ingredient.ComplexIngredientService
import services.meal.{ MealEntry, MealService }
import services.nutrient.{ AmountEvaluation, Nutrient, NutrientMap, NutrientService }
import services.recipe.RecipeService
import services.{ FoodId, MealId, RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.implicits._
import spire.math.Natural
import utils.DBIOUtil
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.collection.MapUtil

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait StatsService {

  def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats]

  def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountMap]]
  def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountMap]]

  def nutrientsOfMeal(userId: UserId, mealId: MealId): Future[NutrientAmountMap]
}

object StatsService {

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      ec: ExecutionContext
  ) extends StatsService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats] =
      db.run(companion.nutrientsOverTime(userId, requestInterval))

    override def nutrientsOfFood(foodId: FoodId): Future[Option[NutrientAmountMap]] =
      db.run(companion.nutrientsOfFood(foodId))

    override def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId): Future[Option[NutrientAmountMap]] =
      db.run(companion.nutrientsOfRecipe(userId, recipeId))

    override def nutrientsOfMeal(userId: UserId, mealId: MealId): Future[NutrientAmountMap] =
      db.run(companion.nutrientsOfMeal(userId, mealId))

  }

  trait Companion {
    def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Stats]

    def nutrientsOfFood(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfRecipe(userId: UserId, recipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]]

    def nutrientsOfMeal(userId: UserId, mealId: MealId)(implicit ec: ExecutionContext): DBIO[NutrientAmountMap]
  }

  object Live extends Companion {

    override def nutrientsOverTime(
        userId: UserId,
        requestInterval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Stats] = {
      val dateFilter = DBIOUtil.dateFilter(requestInterval.from, requestInterval.to)
      for {
        mealIdsPlain <- Tables.Meal.filter(m => dateFilter(m.consumedOnDate)).map(_.id).result
        mealIds = mealIdsPlain.map(_.transformInto[MealId])
        meals              <- mealIds.traverse(MealService.Live.getMeal(userId, _)).map(_.flatten)
        mealEntries        <- mealIds.flatTraverse(MealService.Live.getMealEntries(userId, _))
        nutrientsPerRecipe <- nutrientsOfRecipeIds(userId, mealEntries.map(_.recipeId))
        allNutrients       <- NutrientService.Live.all
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
        nutrientMap  <- OptionT.liftF(NutrientService.Live.nutrientsOfFood(foodId, None, BigDecimal(1)))
        allNutrients <- OptionT.liftF(NutrientService.Live.all)
      } yield unifyAndCount(
        nutrientMap = nutrientMap,
        totalNumberOfIngredients = 1,
        allNutrients = allNutrients
      )

      transformer.value
    }

    override def nutrientsOfRecipe(
        userId: UserId,
        recipeId: RecipeId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Option[NutrientAmountMap]] = {
      val transformer = for {
        allNutrients      <- OptionT.liftF(NutrientService.Live.all)
        recipeNutrientMap <- nutrientsOfRecipeT(userId, recipeId)
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
        mealEntries        <- MealService.Live.getMealEntries(userId, mealId)
        nutrientsPerRecipe <- nutrientsOfRecipeIds(userId, mealEntries.map(_.recipeId))
        allNutrients       <- NutrientService.Live.all
      } yield nutrientAmountMapOfMealEntries(mealEntries, nutrientsPerRecipe, allNutrients)

    private def nutrientsOfRecipeIds(
        userId: UserId,
        recipeIds: Seq[RecipeId]
    )(implicit ec: ExecutionContext): DBIO[Map[RecipeId, RecipeNutrientMap]] =
      recipeIds.distinct
        .traverse { recipeId =>
          nutrientsOfRecipeT(userId, recipeId)
            .map(recipeId -> _)
            .value
        }
        .map(_.flatten.toMap)

    private def nutrientsOfRecipeT(
        userId: UserId,
        recipeId: RecipeId
    )(implicit
        ec: ExecutionContext
    ): OptionT[DBIO, RecipeNutrientMap] =
      for {
        recipe             <- OptionT(RecipeService.Live.getRecipe(userId, recipeId))
        ingredients        <- OptionT.liftF(RecipeService.Live.getIngredients(userId, recipeId))
        complexIngredients <- OptionT.liftF(ComplexIngredientService.Live.all(userId, recipeId))
        nutrients          <- OptionT.liftF(NutrientService.Live.nutrientsOfIngredients(ingredients))
        recipeNutrientMapsOfComplexNutrients <-
          complexIngredients
            .traverse { complexIngredient =>
              nutrientsOfRecipeT(userId, complexIngredient.complexFoodId)
                .map(recipeNutrientMap =>
                  recipeNutrientMap.copy(nutrientMap = complexIngredient.factor *: recipeNutrientMap.nutrientMap)
                )
            }
      } yield RecipeNutrientMap(
        recipe = recipe,
        nutrientMap = nutrients + recipeNutrientMapsOfComplexNutrients.map(_.nutrientMap).qsum,
        foodIds = ingredients.map(_.foodId).toSet ++ recipeNutrientMapsOfComplexNutrients.flatMap(_.foodIds)
      )

    private def nutrientAmountMapOfMealEntries(
        mealEntries: Seq[MealEntry],
        nutrientsPerRecipe: Map[RecipeId, RecipeNutrientMap],
        allNutrients: Seq[Nutrient]
    ): NutrientAmountMap = {
      val nutrientMap = mealEntries.map { mealEntry =>
        val recipeNutrientMap = nutrientsPerRecipe(mealEntry.recipeId)
        (mealEntry.numberOfServings / recipeNutrientMap.recipe.numberOfServings) *: recipeNutrientMap.nutrientMap
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
