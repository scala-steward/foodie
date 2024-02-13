package services.reference

case class ReferenceEntryUpdate(
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
