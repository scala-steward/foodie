package db.daos.ingredient

import db.generated.Tables
import db.{ IngredientId, RecipeId, UserId }
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

case class IngredientKey(
    userId: UserId,
    recipeId: RecipeId,
    ingredientId: IngredientId
)

object IngredientKey {

  def of(row: Tables.RecipeIngredientRow): IngredientKey =
    IngredientKey(
      userId = row.userId.transformInto[UserId],
      recipeId = row.recipeId.transformInto[RecipeId],
      ingredientId = row.id.transformInto[IngredientId]
    )

}
