package db.daos.referenceMap

import db.DAOActions
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ReferenceMapRow, Tables.ReferenceMap, ReferenceMapKey]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ReferenceMapRow, Tables.ReferenceMap, ReferenceMapKey](
      Tables.ReferenceMap,
      (table, key) =>
        table.userId === key.userId.transformInto[UUID] && table.id === key.referenceMapId.transformInto[UUID],
      ReferenceMapKey.of
    ) with DAO

}
