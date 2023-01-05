package db.daos.complexIngredient

import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, ReferenceMapId, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class ComplexIngredientKey(
    recipeId: RecipeId,
    complexFoodId: ComplexFoodId
)

object ComplexIngredientKey {

  def of(row: Tables.ComplexIngredientRow): ComplexIngredientKey =
    ComplexIngredientKey(
      row.recipeId.transformInto[RecipeId],
      row.complexFoodId.transformInto[ComplexFoodId]
    )

}
