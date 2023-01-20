package db.daos.recipe

import db.generated.Tables
import db.{ RecipeId, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class RecipeKey(
    userId: UserId,
    recipeId: RecipeId
)

object RecipeKey {

  def of(row: Tables.RecipeRow): RecipeKey =
    RecipeKey(
      row.userId.transformInto[UserId],
      row.id.transformInto[RecipeId]
    )

}
