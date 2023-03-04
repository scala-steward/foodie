package services.reference

import cats.data.OptionT
import cats.syntax.traverse._
import db.daos.referenceMap.ReferenceMapKey
import db.daos.referenceMapEntry.ReferenceMapEntryKey
import db.generated.Tables
import db.{ NutrientCode, ReferenceMapId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.nutrient.{ FullTableConstants, Nutrient, ReferenceNutrientMap }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: ReferenceService.Companion
)(implicit
    ec: ExecutionContext
) extends ReferenceService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def allReferenceMaps(userId: UserId): Future[Seq[ReferenceMap]] =
    db.run(companion.allReferenceMaps(userId))

  override def getReferenceNutrientsMap(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[Option[ReferenceNutrientMap]] =
    db.run(companion.getReferenceNutrientsMap(userId, referenceMapId))

  override def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId): Future[Option[ReferenceMap]] =
    db.run(companion.getReferenceMap(userId, referenceMapId))

  // TODO: Remove 'traverse'
  override def allReferenceTrees(userId: UserId): Future[List[ReferenceTree]] = {
    val action = for {
      referenceMaps <- companion.allReferenceMaps(userId)
      referenceTrees <- referenceMaps.traverse(referenceMap =>
        OptionT(
          companion
            .getReferenceNutrientsMap(userId, referenceMap.id)
        )
          .map(ReferenceTree(referenceMap, _))
          .value
      )
    } yield referenceTrees.flatten.toList

    db.run(action.transactionally)
  }

  override def createReferenceMap(
      userId: UserId,
      referenceMapCreation: ReferenceMapCreation
  ): Future[ServerError.Or[ReferenceMap]] =
    db.run(
      companion.createReferenceMap(userId, UUID.randomUUID().transformInto[ReferenceMapId], referenceMapCreation)
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ReferenceMap.Creation(error.getMessage).asServerError)
      }

  override def updateReferenceMap(
      userId: UserId,
      referenceMapUpdate: ReferenceMapUpdate
  ): Future[ServerError.Or[ReferenceMap]] =
    db.run(companion.updateReferenceMap(userId, referenceMapUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ReferenceMap.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, referenceMapId: ReferenceMapId): Future[Boolean] =
    db.run(companion.delete(userId, referenceMapId))

  override def allReferenceEntries(userId: UserId, referenceMapId: ReferenceMapId): Future[List[ReferenceEntry]] =
    db.run(companion.allReferenceEntries(userId, Seq(referenceMapId)))

  override def addReferenceEntry(
      userId: UserId,
      referenceEntryCreation: ReferenceEntryCreation
  ): Future[ServerError.Or[ReferenceEntry]] =
    db.run(companion.addReferenceEntry(userId, referenceEntryCreation))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ReferenceMap.Entry.Creation(error.getMessage).asServerError)
      }

  override def updateReferenceEntry(
      userId: UserId,
      referenceEntryUpdate: ReferenceEntryUpdate
  ): Future[ServerError.Or[ReferenceEntry]] =
    db.run(companion.updateReferenceEntry(userId, referenceEntryUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ReferenceMap.Entry.Update(error.getMessage).asServerError)
      }

  override def deleteReferenceEntry(
      userId: UserId,
      referenceMapId: ReferenceMapId,
      nutrientCode: NutrientCode
  ): Future[Boolean] =
    db.run(companion.deleteReferenceEntry(userId, referenceMapId, nutrientCode))
      .recover { _ => false }

}

object Live {

  class Companion @Inject() (
      referenceMapDao: db.daos.referenceMap.DAO,
      referenceMapEntryDao: db.daos.referenceMapEntry.DAO,
      fullTableConstants: FullTableConstants
  ) extends ReferenceService.Companion {

    override def allReferenceMaps(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ReferenceMap]] =
      referenceMapDao
        .findAllFor(userId)
        .map(
          _.map(_.transformInto[ReferenceMap])
        )

    override def getReferenceNutrientsMap(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[Option[ReferenceNutrientMap]] =
      for {
        referenceEntries <- allReferenceEntries(userId, Seq(referenceMapId))
      } yield referenceEntries
        .traverse { referenceEntry =>
          nutrientNameByCode(referenceEntry.nutrientCode)
            .map(_ -> referenceEntry.amount)
        }
        .map(_.toMap)

    override def getReferenceNutrientsMaps(
        userId: UserId,
        referenceMapIds: Seq[ReferenceMapId]
    )(implicit
        ec: ExecutionContext
    ): DBIO[Seq[ReferenceNutrientMap]] = ???

    override def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[ReferenceMap]] =
      OptionT(referenceMapDao.find(ReferenceMapKey(userId, referenceMapId)))
        .map(_.transformInto[ReferenceMap])
        .value

    override def createReferenceMap(
        userId: UserId,
        id: ReferenceMapId,
        referenceMapCreation: ReferenceMapCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceMap] = {
      val referenceMap    = ReferenceMapCreation.create(id, referenceMapCreation)
      val referenceMapRow = (referenceMap, userId).transformInto[Tables.ReferenceMapRow]
      referenceMapDao
        .insert(referenceMapRow)
        .map(_.transformInto[ReferenceMap])
    }

    override def updateReferenceMap(userId: UserId, referenceMapUpdate: ReferenceMapUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceMap] = {
      val findAction =
        OptionT(getReferenceMap(userId, referenceMapUpdate.id)).getOrElseF(notFound)
      for {
        referenceMap <- findAction
        _ <- referenceMapDao.update(
          (
            ReferenceMapUpdate
              .update(referenceMap, referenceMapUpdate),
            userId
          )
            .transformInto[Tables.ReferenceMapRow]
        )
        updatedReferenceMap <- findAction
      } yield updatedReferenceMap
    }

    override def delete(userId: UserId, referenceMapId: ReferenceMapId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      referenceMapDao
        .delete(ReferenceMapKey(userId, referenceMapId))
        .map(_ > 0)

    override def allReferenceEntries(userId: UserId, referenceMapIds: Seq[ReferenceMapId])(implicit
        ec: ExecutionContext
    ): DBIO[List[ReferenceEntry]] =
      for {
        matchingReferenceMaps <- referenceMapDao.allOf(userId, referenceMapIds)
        referenceEntries <-
          referenceMapEntryDao
            // TODO: Reconsider the conversion to and from ReferenceMapId here, and in the DAO.
            .findAllFor(matchingReferenceMaps.map(_.id.transformInto[ReferenceMapId]))
            .map(_.map(_.transformInto[ReferenceEntry]).toList)
      } yield referenceEntries

    override def addReferenceEntry(
        userId: UserId,
        referenceEntryCreation: ReferenceEntryCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceEntry] = {
      val referenceEntry = ReferenceEntryCreation.create(referenceEntryCreation)
      val referenceEntryRow =
        (referenceEntry, referenceEntryCreation.referenceMapId).transformInto[Tables.ReferenceEntryRow]
      ifReferenceMapExists(userId, referenceEntryCreation.referenceMapId) {
        referenceMapEntryDao
          .insert(referenceEntryRow)
          .map(_.transformInto[ReferenceEntry])
      }
    }

    override def updateReferenceEntry(userId: UserId, referenceEntryUpdate: ReferenceEntryUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ReferenceEntry] = {
      val findAction =
        OptionT(
          referenceMapEntryDao.find(
            ReferenceMapEntryKey(referenceEntryUpdate.referenceMapId, referenceEntryUpdate.nutrientCode)
          )
        )
          .getOrElseF(DBIO.failed(DBError.Reference.EntryNotFound))
      for {
        referenceEntryRow <- findAction
        _ <- ifReferenceMapExists(userId, referenceEntryRow.referenceMapId.transformInto[ReferenceMapId]) {
          referenceMapEntryDao.update(
            (
              ReferenceEntryUpdate
                .update(referenceEntryRow.transformInto[ReferenceEntry], referenceEntryUpdate),
              referenceEntryRow.referenceMapId.transformInto[ReferenceMapId]
            )
              .transformInto[Tables.ReferenceEntryRow]
          )
        }
        updatedReferenceEntryRow <- findAction
      } yield updatedReferenceEntryRow.transformInto[ReferenceEntry]
    }

    override def deleteReferenceEntry(userId: UserId, referenceMapId: ReferenceMapId, nutrientCode: NutrientCode)(
        implicit ec: ExecutionContext
    ): DBIO[Boolean] =
      for {
        exists <- referenceMapDao.exists(ReferenceMapKey(userId, referenceMapId))
        result <-
          if (exists)
            referenceMapEntryDao
              .delete(ReferenceMapEntryKey(referenceMapId, nutrientCode))
              .map(_ > 0)
          else DBIO.successful(false)
      } yield result

    private def nutrientNameByCode(nutrientCode: Int): Option[Nutrient] =
      fullTableConstants.allNutrients
        .get(nutrientCode.transformInto[NutrientCode])

    private def ifReferenceMapExists[A](
        userId: UserId,
        id: ReferenceMapId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      referenceMapDao.exists(ReferenceMapKey(userId, id)).flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.Reference.MapNotFound)
  }

}
