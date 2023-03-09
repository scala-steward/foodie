package db.daos.referenceMapEntry

import db.generated.Tables
import db.{ DAOActions, ReferenceMapId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ReferenceEntryRow, ReferenceMapEntryKey] {

  override def keyOf: Tables.ReferenceEntryRow => ReferenceMapEntryKey = ReferenceMapEntryKey.of

  def findAllFor(referenceMapIds: Seq[ReferenceMapId]): DBIO[Seq[Tables.ReferenceEntryRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ReferenceEntryRow, Tables.ReferenceEntry, ReferenceMapEntryKey](
      Tables.ReferenceEntry,
      (table, key) =>
        table.referenceMapId === key.referenceMapId.transformInto[UUID] &&
          table.nutrientCode === key.nutrientCode.transformInto[Int]
    ) with DAO {

      override def findAllFor(referenceMapIds: Seq[ReferenceMapId]): DBIO[Seq[Tables.ReferenceEntryRow]] = {
        val untypedIds = referenceMapIds.distinct.map(_.transformInto[UUID])
        Tables.ReferenceEntry
          .filter(_.referenceMapId.inSetBind(untypedIds))
          .result
      }

    }

}
