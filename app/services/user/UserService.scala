package services.user

import services.{ SessionId, UserId }
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait UserService {
  def get(userId: UserId): Future[Option[User]]
  def getByNickname(nickname: String): Future[Option[User]]

  def getByIdentifier(string: String): Future[Seq[User]]

  def add(user: User): Future[Boolean]

  def update(userId: UserId, userUpdate: UserUpdate): Future[User]

  def updatePassword(userId: UserId, password: String): Future[Boolean]
  def delete(userId: UserId): Future[Boolean]

  def addSession(userId: UserId): Future[SessionId]

  def deleteSession(userId: UserId, sessionId: SessionId): Future[Boolean]

  def deleteAllSessions(userId: UserId): Future[Boolean]

  def existsSession(userId: UserId, sessionId: SessionId): Future[Boolean]
}

object UserService {

  trait Companion {
    def get(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByNickname(nickname: String)(implicit executionContext: ExecutionContext): DBIO[Option[User]]
    def getByIdentifier(string: String)(implicit executionContext: ExecutionContext): DBIO[Seq[User]]
    def add(user: User)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def update(userId: UserId, userUpdate: UserUpdate)(implicit executionContext: ExecutionContext): DBIO[User]
    def updatePassword(userId: UserId, password: String)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def delete(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def addSession(userId: UserId, sessionId: SessionId)(implicit executionContext: ExecutionContext): DBIO[SessionId]
    def deleteSession(userId: UserId, sessionId: SessionId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def deleteAllSessions(userId: UserId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
    def existsSession(userId: UserId, sessionId: SessionId)(implicit executionContext: ExecutionContext): DBIO[Boolean]
  }

}
