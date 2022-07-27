package services.recipe

import services.MeasureId

case class AmountUnit(
    measureId: MeasureId,
    factor: BigDecimal
)
