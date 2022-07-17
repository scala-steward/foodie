package services.recipe

import java.util.UUID

case class AmountUnit(
    measureId: UUID,
    factor: BigDecimal
)
