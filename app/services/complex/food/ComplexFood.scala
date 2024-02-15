package services.complex.food

import db.{ RecipeId, UserId }
import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.recipe.Recipe
import utils.TransformerUtils.Implicits._

import java.util.UUID

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

  case class TransformableToDB(
      userId: UserId,
      complexFood: ComplexFood
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.ComplexFoodRow] = { transformable =>
    Tables.ComplexFoodRow(
      recipeId = transformable.complexFood.recipeId.transformInto[UUID],
      amountGrams = transformable.complexFood.amountGrams,
      amountMilliLitres = transformable.complexFood.amountMilliLitres,
      userId = transformable.userId.transformInto[UUID]
    )
  }

}
