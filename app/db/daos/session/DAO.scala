package db.daos.session

import db.generated.Tables
import db.{ DAOActions, UserId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.SessionRow, SessionKey] {
  def deleteAllFor(userId: UserId): DBIO[Int]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.SessionRow, Tables.Session, SessionKey](
      Tables.Session,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.sessionId.transformInto[UUID],
      SessionKey.of
    ) with DAO {

      override def deleteAllFor(userId: UserId): DBIO[Int] =
        Tables.Session
          .filter(_.userId === userId.transformInto[UUID])
          .delete

    }

}
