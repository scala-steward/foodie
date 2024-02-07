package db.daos.mealEntry

import db.generated.Tables
import db.{ MealEntryId, MealId, UserId }
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

case class MealEntryKey(
    userId: UserId,
    mealId: MealId,
    id: MealEntryId
)

object MealEntryKey {

  def of(row: Tables.MealEntryRow): MealEntryKey =
    MealEntryKey(
      row.userId.transformInto[UserId],
      row.mealId.transformInto[MealId],
      row.id.transformInto[MealEntryId]
    )

}
