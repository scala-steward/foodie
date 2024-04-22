package db.daos.profile

import db.{ DAOActions, UserId }
import db.generated.Tables
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile.api._
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ProfileRow, ProfileKey] {

  override val keyOf: Tables.ProfileRow => ProfileKey = ProfileKey.of

  def findAllFor(userId: UserId): DBIO[Seq[Tables.ProfileRow]]

}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ProfileRow, Tables.Profile, ProfileKey](
      Tables.Profile,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.profileId.transformInto[UUID]
    ) with DAO {

      override def findAllFor(userId: UserId): DBIO[Seq[Tables.ProfileRow]] =
        Tables.Profile
          .filter(
            _.userId === userId.transformInto[UUID]
          )
          .result

    }

}
