package services.profile

import db.{ProfileId, UserId}
import errors.ServerError
import services.DBError
import slick.dbio.DBIO

import scala.concurrent.{ExecutionContext, Future}

trait ProfileService {

  def all(userId: UserId): Future[Seq[Profile]]

  def get(userId: UserId, profileId: ProfileId): Future[Option[Profile]]

  def create(userId: UserId, profileCreation: ProfileCreation): Future[ServerError.Or[Profile]]

  def update(userId: UserId, profileId: ProfileId, profileUpdate: ProfileUpdate): Future[ServerError.Or[Profile]]

  def delete(userId: UserId, profileId: ProfileId): Future[Boolean]

}

object ProfileService {

  trait Companion {

    def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Profile]]

    def get(userId: UserId, profileId: ProfileId)(implicit ec: ExecutionContext): DBIO[Option[Profile]]

    def create(userId: UserId, profileCreation: ProfileCreation)(implicit ec: ExecutionContext): DBIO[Profile]

    def update(userId: UserId, profileId: ProfileId, profileUpdate: ProfileUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[Profile]

    def delete(userId: UserId, profileId: ProfileId)(implicit ec: ExecutionContext): DBIO[Boolean]

    final def notFound[A]: DBIO[A] = DBIO.failed(DBError.Profile.NotFound)

  }

}
