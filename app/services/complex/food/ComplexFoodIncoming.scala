package services.complex.food

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.RecipeId
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexFoodIncoming(
    recipeId: RecipeId,
    amount: BigDecimal,
    unit: ComplexFoodUnit
)

object ComplexFoodIncoming {

  implicit val toDB: Transformer[ComplexFoodIncoming, Tables.ComplexFoodRow] = complexFood =>
    Tables.ComplexFoodRow(
      recipeId = complexFood.recipeId.transformInto[UUID],
      amount = complexFood.amount,
      unit = complexFood.unit.entryName
    )

}
