package controllers.stats

case class NutrientInformation(
    name: String,
    unit: NutrientUnit,
    amount: BigDecimal
)
