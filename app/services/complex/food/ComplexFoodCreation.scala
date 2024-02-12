package services.complex.food

import db.generated.Tables
import db.{ RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexFoodCreation(
    recipeId: RecipeId,
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFoodCreation {

  case class TransformableToDB(
      userId: UserId,
      complexFoodCreation: ComplexFoodCreation
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.ComplexFoodRow] = { transformableToDB =>
    Tables.ComplexFoodRow(
      userId = transformableToDB.userId.transformInto[UUID],
      recipeId = transformableToDB.complexFoodCreation.recipeId.transformInto[UUID],
      amountGrams = transformableToDB.complexFoodCreation.amountGrams,
      amountMilliLitres = transformableToDB.complexFoodCreation.amountMilliLitres
    )
  }

  def create(
      name: String,
      description: Option[String],
      complexFoodCreation: ComplexFoodCreation
  ): ComplexFood = {
    ComplexFood(
      recipeId = complexFoodCreation.recipeId,
      name = name,
      description = description,
      amountGrams = complexFoodCreation.amountGrams,
      amountMilliLitres = complexFoodCreation.amountMilliLitres
    )
  }

}
