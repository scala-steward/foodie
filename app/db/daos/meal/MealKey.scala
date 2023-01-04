package db.daos.meal

import db.generated.Tables
import db.{MealId, UserId}
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class MealKey(
    userId: UserId,
    mealId: MealId
)

object MealKey {

  def of(row: Tables.MealRow): MealKey =
    MealKey(
      row.userId.transformInto[UserId],
      row.id.transformInto[MealId]
    )

}
