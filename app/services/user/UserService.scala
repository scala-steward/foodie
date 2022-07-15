package services.user

import cats.data.OptionT
import db.generated.Tables
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import shapeless.tag.@@
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._

trait UserService {
  def get(userId: UUID @@ UserId): Future[Option[User]]
}

object UserService {

  trait Companion {
    def get(userId: UUID @@ UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends UserService
      with HasDatabaseConfigProvider[PostgresProfile] {
    override def get(userId: UUID @@ UserId): Future[Option[User]] = db.run(companion.get(userId))
  }

  object Live extends Companion {

    def get(userId: UUID @@ UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT(
        Tables.User
          .filter(_.id === (userId: UUID))
          .result
          .headOption: DBIO[Option[Tables.UserRow]]
      )
        .map(_.transformInto[User])
        .value

  }

}
