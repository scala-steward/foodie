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

  case class TransformableFromDB(
      row: Tables.ComplexFoodRow,
      recipe: Recipe
  )

  implicit val fromDB: Transformer[TransformableFromDB, ComplexFood] = { transformableFromDB =>
    ComplexFood(
      recipeId = transformableFromDB.row.recipeId.transformInto[RecipeId],
      name = transformableFromDB.recipe.name,
      description = transformableFromDB.recipe.description,
      amountGrams = transformableFromDB.row.amountGrams,
      amountMilliLitres = transformableFromDB.row.amountMilliLitres
    )
  }

}
