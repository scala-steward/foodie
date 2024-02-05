package db.daos.complexIngredient

import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class ComplexIngredientKey(
    userId: UserId,
    recipeId: RecipeId,
    complexFoodId: ComplexFoodId
)

object ComplexIngredientKey {

  def of(row: Tables.ComplexIngredientRow): ComplexIngredientKey =
    ComplexIngredientKey(
      row.userId.transformInto[UserId],
      row.recipeId.transformInto[RecipeId],
      row.complexFoodId.transformInto[ComplexFoodId]
    )

}
