package services.reference

import db.{ NutrientCode, ReferenceMapId, UserId }
import errors.ServerError
import services.nutrient.ReferenceNutrientMap
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait ReferenceService {
  def allReferenceMaps(userId: UserId): Future[Seq[ReferenceMap]]

  def getReferenceNutrientsMap(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[Option[ReferenceNutrientMap]]

  def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId): Future[Option[ReferenceMap]]

  def allReferenceTrees(userId: UserId): Future[List[ReferenceTree]]

  def createReferenceMap(
      userId: UserId,
      referenceMapCreation: ReferenceMapCreation
  ): Future[ServerError.Or[ReferenceMap]]

  def updateReferenceMap(
      userId: UserId,
      referenceMapUpdate: ReferenceMapUpdate
  ): Future[ServerError.Or[ReferenceMap]]

  def delete(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[Boolean]

  def allReferenceEntries(
      userId: UserId,
      referenceMapId: ReferenceMapId
  ): Future[List[ReferenceEntry]]

  def addReferenceEntry(
      userId: UserId,
      referenceEntryCreation: ReferenceEntryCreation
  ): Future[ServerError.Or[ReferenceEntry]]

  def updateReferenceEntry(
      userId: UserId,
      referenceEntryUpdate: ReferenceEntryUpdate
  ): Future[ServerError.Or[ReferenceEntry]]

  def deleteReferenceEntry(
      userId: UserId,
      referenceMapId: ReferenceMapId,
      nutrientCode: NutrientCode
  ): Future[Boolean]

}

object ReferenceService {

  trait Companion {
    def allReferenceMaps(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ReferenceMap]]

    def getReferenceNutrientsMap(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[Option[ReferenceNutrientMap]]

    def getReferenceNutrientsMaps(
        userId: UserId,
        referenceMapIds: Seq[ReferenceMapId]
    )(implicit ec: ExecutionContext): DBIO[Map[ReferenceMapId, ReferenceNutrientMap]]

    def getReferenceMap(userId: UserId, referenceMapId: ReferenceMapId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[ReferenceMap]]

    def createReferenceMap(
        userId: UserId,
        id: ReferenceMapId,
        referenceMapCreation: ReferenceMapCreation
    )(implicit ec: ExecutionContext): DBIO[ReferenceMap]

    def updateReferenceMap(
        userId: UserId,
        referenceMapUpdate: ReferenceMapUpdate
    )(implicit ec: ExecutionContext): DBIO[ReferenceMap]

    def delete(
        userId: UserId,
        referenceMapId: ReferenceMapId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    def allReferenceEntries(
        userId: UserId,
        referenceMapIds: Seq[ReferenceMapId]
    )(implicit ec: ExecutionContext): DBIO[Map[ReferenceMapId, List[ReferenceEntry]]]

    def addReferenceEntry(
        userId: UserId,
        referenceEntryCreation: ReferenceEntryCreation
    )(implicit ec: ExecutionContext): DBIO[ReferenceEntry]

    def updateReferenceEntry(
        userId: UserId,
        referenceEntryUpdate: ReferenceEntryUpdate
    )(implicit ec: ExecutionContext): DBIO[ReferenceEntry]

    def deleteReferenceEntry(
        userId: UserId,
        referenceMapId: ReferenceMapId,
        nutrientCode: NutrientCode
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

}
