package db.daos.complexFood

import db.generated.Tables
import db.{ RecipeId, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class ComplexFoodKey(
    userId: UserId,
    recipeId: RecipeId
)

object ComplexFoodKey {

  def of(row: Tables.ComplexFoodRow): ComplexFoodKey =
    ComplexFoodKey(
      row.userId.transformInto[UserId],
      row.recipeId.transformInto[RecipeId]
    )

}
