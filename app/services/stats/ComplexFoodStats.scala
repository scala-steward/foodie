package services.stats

import services.complex.food.ComplexFoodUnit

case class ComplexFoodStats(
    nutrientAmountMap: NutrientAmountMap,
    unit: ComplexFoodUnit
)
