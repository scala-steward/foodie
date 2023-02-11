package services.complex.food

import db.RecipeId
import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.recipe.Recipe
import utils.TransformerUtils.Implicits._

case class ComplexFood(
    recipeId: RecipeId,
    name: String,
    description: Option[String],
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFood {

  implicit val fromDB: Transformer[(Tables.ComplexFoodRow, Recipe), ComplexFood] = { case (food, recipe) =>
    ComplexFood(
      recipeId = food.recipeId.transformInto[RecipeId],
      name = recipe.name,
      description = recipe.description,
      amountGrams = food.amountGrams,
      amountMilliLitres = food.amountMilliLitres
    )
  }

}
