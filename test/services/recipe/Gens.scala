package services.recipe

import org.scalacheck.Gen
import services._
import spire.math.Natural

object Gens {

  val recipeCreationGen: Gen[RecipeCreation] = for {
    name             <- GenUtils.nonEmptyAsciiString
    description      <- Gen.option(GenUtils.nonEmptyAsciiString)
    numberOfServings <- GenUtils.smallBigDecimalGen
  } yield RecipeCreation(
    name = name,
    description = description,
    numberOfServings = numberOfServings
  )

  def recipePreUpdateGen: Gen[RecipePreUpdate] =
    for {
      name             <- GenUtils.nonEmptyAsciiString
      description      <- Gen.option(GenUtils.nonEmptyAsciiString)
      numberOfServings <- GenUtils.smallBigDecimalGen
    } yield RecipePreUpdate(
      name = name,
      description = description,
      numberOfServings = numberOfServings
    )

  def amountUnitGen(food: Food): Gen[AmountUnit] = {
    for {
      measureId <- GenUtils.optionalOneOf(food.measures.map(_.id))
      factor    <- GenUtils.smallBigDecimalGen
    } yield AmountUnit(
      measureId = measureId,
      factor = factor
    )
  }

  val ingredientGen: Gen[IngredientParameters] =
    for {
      food       <- GenUtils.foodGen
      amountUnit <- amountUnitGen(food)
    } yield IngredientParameters(
      ingredientPreCreation = IngredientPreCreation(
        foodId = food.id,
        amountUnit = amountUnit
      )
    )

  def recipeParametersGen(maxNumberOfIngredients: Natural = Natural(20)): Gen[RecipeParameters] =
    for {
      recipeCreation       <- recipeCreationGen
      ingredientParameters <- GenUtils.nonEmptyListOfAtMost(maxNumberOfIngredients, ingredientGen)
    } yield RecipeParameters(
      recipeCreation = recipeCreation,
      ingredientParameters = ingredientParameters.toList
    )

  def ingredientPreUpdateGen(foodId: FoodId): Gen[IngredientPreUpdate] = {
    val food = GenUtils.allFoods(foodId)
    amountUnitGen(food).map(IngredientPreUpdate.apply)
  }

}
