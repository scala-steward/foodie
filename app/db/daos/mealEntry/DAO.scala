package db.daos.mealEntry

import db.generated.Tables
import db.{ DAOActions, MealEntryId, MealId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.MealEntryRow, MealEntryId] {

  override def keyOf: Tables.MealEntryRow => MealEntryId = _.id.transformInto[MealEntryId]

  def findAllFor(mealId: MealId): DBIO[Seq[Tables.MealEntryRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealEntryRow, Tables.MealEntry, MealEntryId](
      Tables.MealEntry,
      (table, key) => table.id === key.transformInto[UUID]
    ) with DAO {

      override def findAllFor(mealId: MealId): DBIO[Seq[Tables.MealEntryRow]] =
        Tables.MealEntry
          .filter(
            _.mealId === mealId.transformInto[UUID]
          )
          .result

    }

}
