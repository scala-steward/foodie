package db.daos.user

import db.generated.Tables
import db.{ DAOActions, UserId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.UserRow, UserId] {
  def findByNickname(nickname: String): DBIO[Seq[Tables.UserRow]]

  def findByIdentifier(identifier: String): DBIO[Seq[Tables.UserRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.UserRow, Tables.User, UserId](
      Tables.User,
      (table, key) => table.id === key.transformInto[UUID],
      _.id.transformInto[UserId]
    ) with DAO {

      override def findByNickname(nickname: String): DBIO[Seq[Tables.UserRow]] =
        Tables.User
          .filter(_.nickname === nickname)
          .result

      override def findByIdentifier(identifier: String): DBIO[Seq[Tables.UserRow]] =
        Tables.User
          .filter(user => user.email === identifier || user.nickname === identifier)
          .result

    }

}
