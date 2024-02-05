package services.complex.food

import db.{ RecipeId, UserId }
import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexFoodIncoming(
    recipeId: RecipeId,
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFoodIncoming {

  case class TransformableToDB(
      userId: UserId,
      complexFood: ComplexFoodIncoming
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
