package services.user

import cats.data.OptionT
import db.daos.session.SessionKey
import db.generated.Tables
import db.{ SessionId, UserId }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import security.Hash
import security.jwt.JwtConfiguration
import services.DBError
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.sql.Date
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: UserService.Companion
)(implicit
    executionContext: ExecutionContext
) extends UserService
    with HasDatabaseConfigProvider[PostgresProfile] {
  override def get(userId: UserId): Future[Option[User]]             = db.run(companion.get(userId))
  override def getByNickname(nickname: String): Future[Option[User]] = db.run(companion.getByNickname(nickname))
  override def getByIdentifier(string: String): Future[Seq[User]]    = db.run(companion.getByIdentifier(string))

  override def add(user: User): Future[Boolean] =
    db.run(companion.add(user))
      .map(_ => true)
      .recover { case _ => false }

  override def update(userId: UserId, userUpdate: UserUpdate): Future[User] =
    db.run(companion.update(userId, userUpdate))

  override def updatePassword(userId: UserId, password: String): Future[Boolean] =
    db.run(companion.updatePassword(userId, password))

  override def delete(userId: UserId): Future[Boolean] = db.run(companion.delete(userId))

  override def addSession(userId: UserId): Future[SessionId] =
    db.run(
      companion.addSession(
        userId,
        UUID.randomUUID().transformInto[SessionId],
        LocalDate.now().transformInto[java.sql.Date]
      )
    )

  override def deleteSession(userId: UserId, sessionId: SessionId): Future[Boolean] =
    db.run(companion.deleteSession(userId, sessionId))

  override def deleteAllSessions(userId: UserId): Future[Boolean] = db.run(companion.deleteAllSessions(userId))

  override def existsSession(userId: UserId, sessionId: SessionId): Future[Boolean] =
    db.run(companion.existsSession(userId, sessionId))

}

object Live {

  class Companion @Inject() (
      userDao: db.daos.user.DAO,
      sessionDao: db.daos.session.DAO
  ) extends UserService.Companion {

    private val jwtConfiguration: JwtConfiguration = JwtConfiguration.default

    private val allowedValidityInDays: Int =
      Math.ceil(jwtConfiguration.restrictedDurationInSeconds.toDouble / 86400).toInt

    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT(userDao.find(userId))
        .map(_.transformInto[User])
        .value

    override def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]] =
      OptionT
        .liftF(userDao.findByNickname(nickname))
        .subflatMap(_.headOption)
        .map(_.transformInto[User])
        .value

    override def getByIdentifier(string: String)(implicit executionContext: ExecutionContext): DBIO[Seq[User]] =
      userDao
        .findByIdentifier(string)
        .map(_.map(_.transformInto[User]))

    override def add(user: User)(implicit executionContext: ExecutionContext): DBIO[Unit] =
      userDao
        .insert(user.transformInto[Tables.UserRow])
        .map(_ => ())

    override def update(userId: UserId, userUpdate: UserUpdate)(implicit
        executionContext: ExecutionContext
    ): DBIO[User] = {
      val findAction = OptionT(get(userId))
        .getOrElseF(DBIO.failed(DBError.User.NotFound))

      for {
        user <- findAction
        _ <- userDao.update(
          UserUpdate
            .update(user, userUpdate)
            .transformInto[Tables.UserRow]
        )
        updatedUser <- findAction
      } yield updatedUser
    }

    override def updatePassword(userId: UserId, password: String)(implicit
        executionContext: ExecutionContext
    ): DBIO[Boolean] = {
      val transformer = for {
        user <- OptionT(get(userId))
        newHash = Hash.fromPassword(
          password,
          user.salt,
          Hash.defaultIterations
        )
        newUser = user.copy(hash = newHash)
        result <- OptionT.liftF(
          userDao.update(newUser.transformInto[Tables.UserRow])
        )
      } yield result

      transformer.getOrElseF(DBIO.failed(DBError.User.NotFound))
    }

    override def delete(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean] =
      userDao
        .delete(userId)
        .map(_ > 0)

    override def addSession(userId: UserId, sessionId: SessionId, createdAt: java.sql.Date)(implicit
        executionContext: ExecutionContext
    ): DBIO[SessionId] = {
      sessionDao
        .deleteAllBefore(
          userId,
          createdAt.toLocalDate
            .minus(allowedValidityInDays, ChronoUnit.DAYS)
            .transformInto[Date]
        )
        .andThen(
          sessionDao
            .insert(
              Tables.SessionRow(
                id = sessionId.transformInto[UUID],
                userId = userId.transformInto[UUID],
                createdAt = createdAt
              )
            )
            .map(_.id.transformInto[SessionId])
        )
    }

    override def deleteSession(userId: UserId, sessionId: SessionId)(implicit
        executionContext: ExecutionContext
    ): DBIO[Boolean] =
      sessionDao
        .delete(SessionKey(userId, sessionId))
        .map(_ > 0)

    override def deleteAllSessions(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean] =
      sessionDao
        .deleteAllFor(userId)
        .map(_ > 0)

    override def existsSession(userId: UserId, sessionId: SessionId)(implicit
        executionContext: ExecutionContext
    ): DBIO[Boolean] =
      sessionDao.exists(SessionKey(userId, sessionId))

  }

}
