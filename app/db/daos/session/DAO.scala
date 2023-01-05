package db.daos.session

import db.DAOActions
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.SessionRow, Tables.Session, SessionKey]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.SessionRow, Tables.Session, SessionKey](
      Tables.Session,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.sessionId.transformInto[UUID]
    ) with DAO

}
