package services.recipe

import shapeless.tag.@@

case class AmountUnit(
    measureId: Int @@ MeasureId,
    factor: BigDecimal
)
