package services.stats

import cats.data.NonEmptyList
import db.generated.Tables
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services._
import services.meal.MealCreation
import services.nutrient.{ Nutrient, NutrientService }
import services.recipe._
import slick.jdbc.PostgresProfile.api._
import spire.math.Natural
import utils.TransformerUtils.Implicits._

object StatsGens {

  private val recipeService   = TestUtil.injector.instanceOf[RecipeService]
  private val nutrientService = TestUtil.injector.instanceOf[NutrientService]

  val allFoods: Seq[Food] = DBTestUtil
    .await(recipeService.allFoods)
    .map(food =>
      food.copy(
        measures = food.measures
          .filter(measure => measure.id != AmountUnit.hundredGrams)
      )
    )

  val allNutrients: Seq[Nutrient] = DBTestUtil.await(nutrientService.all)

  val allConversionFactors: Map[(FoodId, MeasureId), BigDecimal] =
    DBTestUtil
      .await(DBTestUtil.dbRun(Tables.ConversionFactor.result))
      .map { row =>
        (row.foodId.transformInto[FoodId], row.measureId.transformInto[MeasureId]) -> row.conversionFactorValue
      }
      .toMap

  lazy val foodGen: Gen[Food] =
    Gen.oneOf(allFoods)

  val smallBigDecimalGen: Gen[BigDecimal] = Gen.choose(BigDecimal(0.001), BigDecimal(1000))

  val recipeCreationGen: Gen[RecipeCreation] = for {
    name             <- Gens.nonEmptyAsciiString
    description      <- Gen.option(Gens.nonEmptyAsciiString)
    numberOfServings <- smallBigDecimalGen
  } yield RecipeCreation(
    name = name,
    description = description,
    numberOfServings = numberOfServings
  )

  val ingredientGen: Gen[IngredientParameters] =
    for {
      food         <- foodGen
      measureId    <- Gens.optionalOneOf(food.measures.map(_.id))
      factor       <- smallBigDecimalGen
      ingredientId <- Gen.uuid.map(_.transformInto[IngredientId])
    } yield IngredientParameters(
      ingredientId = ingredientId,
      ingredientPreCreation = IngredientPreCreation(
        foodId = food.id,
        amountUnit = AmountUnit(
          measureId = measureId,
          factor = factor
        )
      )
    )

  val recipeParametersGen: Gen[RecipeParameters] = for {
    recipeCreation       <- recipeCreationGen
    ingredientParameters <- Gens.listOfAtMost(Natural(20), ingredientGen)
  } yield RecipeParameters(
    recipeCreation = recipeCreation,
    ingredientParameters = ingredientParameters
  )

  def mealEntryGen(recipeIds: NonEmptyList[RecipeId]): Gen[MealEntryParameters] =
    for {
      mealEntryId      <- Gen.uuid.map(_.transformInto[MealEntryId])
      recipeId         <- Gen.oneOf(recipeIds.toList)
      numberOfServings <- smallBigDecimalGen
    } yield MealEntryParameters(
      mealEntryId = mealEntryId,
      mealEntryPreCreation = MealEntryPreCreation(
        recipeId = recipeId,
        numberOfServings = numberOfServings
      )
    )

  def mealGen(recipeIds: NonEmptyList[RecipeId]): Gen[MealParameters] =
    for {
      mealId              <- Gen.uuid.map(_.transformInto[MealId])
      mealEntryParameters <- Gens.listOfAtMost(Natural(10), mealEntryGen(recipeIds))
      name                <- Gen.option(Gens.nonEmptyAsciiString)
      date                <- Gens.simpleDateGen
    } yield MealParameters(
      mealId = mealId,
      mealCreation = MealCreation(
        date = date,
        name = name
      ),
      mealEntryParameters = mealEntryParameters
    )

}
