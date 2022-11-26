package services.stats

import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services.recipe._
import services._
import services.nutrient.{ Nutrient, NutrientService }
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

  lazy val foodGen: Gen[Food] =
    Gen.oneOf(allFoods)

  val smallBigDecimalGen: Gen[BigDecimal] = Gen.choose(BigDecimal(0.001), BigDecimal(1000))

  case class RecipeParameters(
      recipeId: RecipeId,
      recipeCreation: RecipeCreation,
      ingredientParameters: List[IngredientParameters]
  )

  case class IngredientParameters(
      ingredientId: IngredientId,
      ingredientCreation: RecipeId => IngredientCreation
  )

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
      ingredientId,
      recipeId =>
        IngredientCreation(
          recipeId = recipeId,
          foodId = food.id,
          amountUnit = AmountUnit(
            measureId = measureId,
            factor = factor
          )
        )
    )

  val recipeParametersGen: Gen[RecipeParameters] = for {
    recipeCreation       <- recipeCreationGen
    recipeId             <- Gen.uuid.map(_.transformInto[RecipeId])
    ingredientParameters <- Gen.listOf(ingredientGen)
  } yield RecipeParameters(
    recipeId = recipeId,
    recipeCreation = recipeCreation,
    ingredientParameters = ingredientParameters
  )

}
