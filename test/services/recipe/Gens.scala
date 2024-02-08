package services.recipe

import db.{ FoodId, IngredientId, RecipeId }
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services._
import spire.math.Natural
import utils.TransformerUtils.Implicits._

object Gens {

  val recipeCreationGen: Gen[RecipeCreation] = for {
    name             <- GenUtils.nonEmptyAsciiString
    description      <- Gen.option(GenUtils.nonEmptyAsciiString)
    numberOfServings <- GenUtils.smallBigDecimalGen
    servingSize      <- Gen.option(GenUtils.nonEmptyAsciiString)
  } yield RecipeCreation(
    name = name,
    description = description,
    numberOfServings = numberOfServings,
    servingSize = servingSize
  )

  val recipeGen: Gen[Recipe] = for {
    id             <- Gen.uuid.map(_.transformInto[RecipeId])
    recipeCreation <- recipeCreationGen
  } yield RecipeCreation.create(id, recipeCreation)

  def recipeUpdateGen(recipeId: RecipeId): Gen[RecipeUpdate] =
    for {
      name             <- GenUtils.nonEmptyAsciiString
      description      <- Gen.option(GenUtils.nonEmptyAsciiString)
      numberOfServings <- GenUtils.smallBigDecimalGen
      servingSize      <- Gen.option(GenUtils.nonEmptyAsciiString)
    } yield RecipeUpdate(
      recipeId,
      name = name,
      description = description,
      numberOfServings = numberOfServings,
      servingSize = servingSize
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

  val ingredientGen: Gen[Ingredient] =
    for {
      id         <- Gen.uuid.map(_.transformInto[IngredientId])
      food       <- GenUtils.foodGen
      amountUnit <- amountUnitGen(food)
    } yield Ingredient(
      id = id,
      foodId = food.id,
      amountUnit = amountUnit
    )

  def fullRecipeGen(maxNumberOfIngredients: Natural = Natural(20)): Gen[FullRecipe] =
    for {
      recipe      <- recipeGen
      ingredients <- GenUtils.nonEmptyListOfAtMost(maxNumberOfIngredients, ingredientGen)
    } yield FullRecipe(
      recipe = recipe,
      ingredients = ingredients.toList
    )

  def ingredientUpdateGen(foodId: FoodId): Gen[IngredientUpdate] = {
    val food = GenUtils.allFoods(foodId)
    amountUnitGen(food).map(IngredientUpdate(_))
  }

}
