package services.complex.food

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.RecipeId
import services.recipe.Recipe
import utils.TransformerUtils.Implicits._

case class ComplexFood(
    recipeId: RecipeId,
    name: String,
    description: Option[String],
    amount: BigDecimal,
    unit: ComplexFoodUnit
)

object ComplexFood {

  implicit val fromDB: Transformer[(Tables.ComplexFoodRow, Recipe), ComplexFood] = {
    case (food, recipe) =>
      ComplexFood(
        recipeId = food.recipeId.transformInto[RecipeId],
        name = recipe.name,
        description = recipe.description,
        amount = food.amount,
        unit = ComplexFoodUnit.withName(food.unit)
      )
  }

}
