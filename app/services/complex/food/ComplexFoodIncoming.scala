package services.complex.food

import db.RecipeId
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

  implicit val toDB: Transformer[ComplexFoodIncoming, Tables.ComplexFoodRow] = complexFood =>
    Tables.ComplexFoodRow(
      recipeId = complexFood.recipeId.transformInto[UUID],
      amountGrams = complexFood.amountGrams,
      amountMilliLitres = complexFood.amountMilliLitres
    )

}
