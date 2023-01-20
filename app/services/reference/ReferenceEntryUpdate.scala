package services.reference

import db.{ NutrientCode, ReferenceMapId }

case class ReferenceEntryUpdate(
    referenceMapId: ReferenceMapId,
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceEntryUpdate {

  def update(
      referenceEntry: ReferenceEntry,
      referenceEntryUpdate: ReferenceEntryUpdate
  ): ReferenceEntry =
    referenceEntry.copy(
      amount = referenceEntryUpdate.amount
    )

}
