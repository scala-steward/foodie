package services.recipe

import services.meal.MeasureId

case class AmountUnit(
    measureId: MeasureId,
    factor: BigDecimal
)
