package services.duplication.reference

import cats.data.OptionT
import db.generated.Tables
import db.{ ReferenceMapId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.common.Transactionally.syntax._
import services.reference.{ ReferenceEntry, ReferenceMap, ReferenceMapCreation, ReferenceService }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: Duplication.Companion,
    referenceServiceCompanion: ReferenceService.Companion
)(implicit
    executionContext: ExecutionContext
) extends Duplication
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def duplicate(
      userId: UserId,
      id: ReferenceMapId,
      timeOfDuplication: SimpleDate
  ): Future[ServerError.Or[ReferenceMap]] = {
    val action = for {
      referenceEntries <- referenceServiceCompanion
        .allReferenceEntries(userId, Seq(id))
        .map(_.getOrElse(id, Seq.empty))
      newReferenceMapId = UUID.randomUUID().transformInto[ReferenceMapId]
      newReferenceMap <- companion.duplicateReferenceMap(
        userId = userId,
        id = id,
        newId = newReferenceMapId,
        timestamp = timeOfDuplication
      )
      _ <- companion.duplicateReferenceEntries(userId, newReferenceMapId, referenceEntries)
    } yield newReferenceMap

    db.runTransactionally(action)
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ReferenceMap.Creation(error.getMessage).asServerError)
      }
  }

}

object Live {

  class Companion @Inject() (
      referenceServiceCompanion: ReferenceService.Companion,
      referenceEntryDao: db.daos.referenceMapEntry.DAO
  ) extends Duplication.Companion {

    override def duplicateReferenceMap(
        userId: UserId,
        id: ReferenceMapId,
        newId: ReferenceMapId,
        timestamp: SimpleDate
    )(implicit ec: ExecutionContext): DBIO[ReferenceMap] = {
      val transformer = for {
        referenceMap <- OptionT(referenceServiceCompanion.getReferenceMap(userId, id))
        inserted <- OptionT.liftF(
          referenceServiceCompanion.createReferenceMap(
            userId,
            newId,
            ReferenceMapCreation(
              name = s"${referenceMap.name} (copy ${SimpleDate.toPrettyString(timestamp)})"
            )
          )
        )
      } yield inserted

      transformer.getOrElseF(referenceServiceCompanion.notFound)
    }

    override def duplicateReferenceEntries(
        userId: UserId,
        newReferenceMapId: ReferenceMapId,
        referenceEntries: Seq[ReferenceEntry]
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[ReferenceEntry]] =
      referenceEntryDao
        .insertAll {
          referenceEntries.map { referenceEntry =>
            (referenceEntry, newReferenceMapId, userId).transformInto[Tables.ReferenceEntryRow]
          }
        }
        .map(_.map(_.transformInto[ReferenceEntry]))

  }

}
