package services.reference

import db.ReferenceMapId

case class ReferenceMapUpdate(
    id: ReferenceMapId,
    name: String
)

object ReferenceMapUpdate {

  def update(referenceMap: ReferenceMap, referenceMapUpdate: ReferenceMapUpdate): ReferenceMap =
    referenceMap.copy(
      name = referenceMapUpdate.name.trim
    )

}
