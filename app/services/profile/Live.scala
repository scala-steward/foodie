package services.profile

import cats.data.OptionT
import db.daos.profile.ProfileKey
import db.{ ProfileId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.syntax.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.common.Transactionally.syntax._
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

case class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: ProfileService.Companion
)(implicit executionContext: ExecutionContext)
    extends ProfileService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all(userId: UserId): Future[Seq[Profile]] =
    db.runTransactionally(companion.all(userId))

  override def get(userId: UserId, profileId: ProfileId): Future[Option[Profile]] =
    db.runTransactionally(companion.get(userId, profileId))

  override def create(
      userId: UserId,
      profileCreation: ProfileCreation
  ): Future[ServerError.Or[Profile]] =
    db.runTransactionally(
      companion.create(userId, UUID.randomUUID().transformInto[ProfileId], profileCreation)
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Profile.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      profileId: ProfileId,
      profileUpdate: ProfileUpdate
  ): Future[ServerError.Or[Profile]] =
    db.runTransactionally(companion.update(userId, profileId, profileUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Profile.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, profileId: ProfileId): Future[Boolean] =
    db.runTransactionally(companion.delete(userId, profileId))

}

object Live {

  case class Companion @Inject() (
      dao: db.daos.profile.DAO
  ) extends ProfileService.Companion {

    override def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Profile]] =
      dao
        .findAllFor(userId)
        .map(_.map(_.transformInto[Profile]))

    override def get(userId: UserId, profileId: ProfileId)(implicit ec: ExecutionContext): DBIO[Option[Profile]] =
      OptionT(
        dao.find(ProfileKey(userId, profileId))
      )
        .map(_.transformInto[Profile])
        .value

    override def create(userId: UserId, profileId: ProfileId, profileCreation: ProfileCreation)(implicit
        ec: ExecutionContext
    ): DBIO[Profile] = {
      val profile    = ProfileCreation.create(profileId, profileCreation)
      val profileRow = Profile.TransformableToDB(userId, profile).transformInto[db.generated.Tables.ProfileRow]
      dao
        .insert(profileRow)
        .map(_.transformInto[Profile])
    }

    override def update(userId: UserId, profileId: ProfileId, profileUpdate: ProfileUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[Profile] = {
      val findAction = OptionT(get(userId, profileId)).getOrElseF(notFound)
      for {
        profile <- findAction
        _ <- dao.update(
          Profile
            .TransformableToDB(
              userId,
              ProfileUpdate.update(profile, profileUpdate)
            )
            .transformInto[db.generated.Tables.ProfileRow]
        )
        updatedProfile <- findAction
      } yield updatedProfile
    }

    override def delete(userId: UserId, profileId: ProfileId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      dao
        .delete(ProfileKey(userId, profileId))
        .map(_ > 0)

  }

}
