package services.reference

case class ReferenceMapUpdate(
    name: String
)

object ReferenceMapUpdate {

  def update(referenceMap: ReferenceMap, referenceMapUpdate: ReferenceMapUpdate): ReferenceMap =
    referenceMap.copy(
      name = referenceMapUpdate.name.trim
    )

}
