package services.stats

import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import play.api.inject.guice.GuiceApplicationBuilder
import services.recipe._
import services.{ Gens, IngredientId, RecipeId }
import utils.TransformerUtils.Implicits._

import scala.concurrent.Await
import scala.concurrent.duration.Duration

object StatsGens {

  private val recipeService = GuiceApplicationBuilder()
    .build()
    .injector
    .instanceOf[RecipeService]

  private val allFoods = Await
    .result(recipeService.allFoods, Duration.Inf)
    .map(food =>
      food.copy(
        measures = food.measures
          .filter(measure => measure.id != AmountUnit.hundredGrams)
      )
    )

  lazy val foodGen: Gen[Food] =
    Gen.oneOf(allFoods)

  val smallBigDecimalGen: Gen[BigDecimal] = Gen.choose(BigDecimal(0.001), BigDecimal(1000))

  case class RecipeParameters(
      recipeId: RecipeId,
      recipeCreation: RecipeCreation,
      ingredientParameters: Seq[IngredientParameters]
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
