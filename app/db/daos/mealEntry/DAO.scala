package db.daos.mealEntry

import db.generated.Tables
import db.{ DAOActions, MealEntryId, MealId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import scala.concurrent.ExecutionContext

trait DAO extends DAOActions[Tables.MealEntryRow, MealEntryId] {

  override def keyOf: Tables.MealEntryRow => MealEntryId = _.id.transformInto[MealEntryId]

  def findAllFor(mealIds: Seq[MealId])(implicit ec: ExecutionContext): DBIO[Map[MealId, Seq[Tables.MealEntryRow]]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealEntryRow, Tables.MealEntry, MealEntryId](
      Tables.MealEntry,
      (table, key) => table.id === key.transformInto[UUID]
    ) with DAO {

      override def findAllFor(
          mealIds: Seq[MealId]
      )(implicit ec: ExecutionContext): DBIO[Map[MealId, Seq[Tables.MealEntryRow]]] = {
        val untypedIds = mealIds.distinct.map(_.transformInto[UUID])
        Tables.MealEntry
          .filter(
            _.mealId.inSetBind(untypedIds)
          )
          .result
          .map { mealEntries =>
            mealEntries
              .groupBy(_.mealId)
              .map { case (mealId, entries) => mealId.transformInto[MealId] -> entries }
          }
      }

    }

}
