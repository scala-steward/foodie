package services.duplication.reference

import db.{ ReferenceMapId, UserId }
import errors.ServerError
import services.reference.{ ReferenceEntry, ReferenceMap }
import slick.dbio.DBIO
import utils.date.SimpleDate

import scala.concurrent.{ ExecutionContext, Future }

trait Duplication {

  def duplicate(
      userId: UserId,
      id: ReferenceMapId,
      timeOfDuplication: SimpleDate
  ): Future[ServerError.Or[ReferenceMap]]

}

object Duplication {

  trait Companion {

    def duplicateReferenceMap(
        userId: UserId,
        id: ReferenceMapId,
        newId: ReferenceMapId,
        timestamp: SimpleDate
    )(implicit ec: ExecutionContext): DBIO[ReferenceMap]

    def duplicateReferenceEntries(
        newReferenceMapId: ReferenceMapId,
        referenceEntries: Seq[ReferenceEntry]
    )(implicit ec: ExecutionContext): DBIO[Seq[ReferenceEntry]]

  }

}
