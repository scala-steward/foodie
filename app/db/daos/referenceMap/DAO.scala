package db.daos.referenceMap

import db.generated.Tables
import db.{DAOActions, ReferenceMapId, UserId}
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ReferenceMapRow, ReferenceMapKey] {

  override val keyOf: Tables.ReferenceMapRow => ReferenceMapKey = ReferenceMapKey.of

  def findAllFor(userId: UserId): DBIO[Seq[Tables.ReferenceMapRow]]

  def allOf(userId: UserId, referenceMapIds: Seq[ReferenceMapId]): DBIO[Seq[Tables.ReferenceMapRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ReferenceMapRow, Tables.ReferenceMap, ReferenceMapKey](
      Tables.ReferenceMap,
      (table, key) =>
        table.userId === key.userId.transformInto[UUID] && table.id === key.referenceMapId.transformInto[UUID]
    ) with DAO {

      override def findAllFor(userId: UserId): DBIO[Seq[Tables.ReferenceMapRow]] =
        Tables.ReferenceMap
          .filter(_.userId === userId.transformInto[UUID])
          .result

      override def allOf(
          userId: UserId,
          referenceMapIds: Seq[ReferenceMapId]
      ): DBIO[Seq[Tables.ReferenceMapRow]] = {
        val untypedIds = referenceMapIds.distinct.map(_.transformInto[UUID])
        Tables.ReferenceMap
          .filter(referenceMap =>
            referenceMap.userId === userId.transformInto[UUID] && referenceMap.id.inSetBind(untypedIds)
          )
          .result
      }

    }

}
