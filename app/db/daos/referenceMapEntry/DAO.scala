package db.daos.referenceMapEntry

import db.generated.Tables
import db.{ DAOActions, NutrientCode }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

trait DAO extends DAOActions[Tables.ReferenceEntryRow, Tables.ReferenceEntry, NutrientCode]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ReferenceEntryRow, Tables.ReferenceEntry, NutrientCode](
      Tables.ReferenceEntry,
      (table, key) => table.nutrientCode === key.transformInto[Int]
    ) with DAO

}
