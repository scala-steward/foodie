package db.daos.user

import db.{ DAOActions, UserId }
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.UserRow, Tables.User, UserId]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.UserRow, Tables.User, UserId](
      Tables.User,
      (table, key) => table.id === key.transformInto[UUID],
      _.id.transformInto[UserId]
    ) with DAO

}
