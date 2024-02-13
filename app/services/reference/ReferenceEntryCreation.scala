package services.reference

import db.NutrientCode

case class ReferenceEntryCreation(
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceEntryCreation {

  def create(referenceNutrientCreation: ReferenceEntryCreation): ReferenceEntry =
    ReferenceEntry(
      nutrientCode = referenceNutrientCreation.nutrientCode,
      amount = referenceNutrientCreation.amount
    )

}
