package db.daos.referenceMapEntry

import db.generated.Tables
import db.{ DAOActions, NutrientCode }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._
import java.util.UUID

trait DAO extends DAOActions[Tables.ReferenceEntryRow, Tables.ReferenceEntry, ReferenceMapEntryKey]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ReferenceEntryRow, Tables.ReferenceEntry, ReferenceMapEntryKey](
      Tables.ReferenceEntry,
      (table, key) =>
        table.referenceMapId === key.referenceMapId.transformInto[UUID] &&
          table.nutrientCode === key.nutrientCode.transformInto[Int],
      ReferenceMapEntryKey.of
    ) with DAO

}
