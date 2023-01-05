package db.daos.mealEntry

import db.{ DAOActions, MealEntryId }
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.MealEntryRow, Tables.MealEntry, MealEntryId]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealEntryRow, Tables.MealEntry, MealEntryId](
      Tables.MealEntry,
      (table, key) => table.id === key.transformInto[UUID]
    ) with DAO

}
