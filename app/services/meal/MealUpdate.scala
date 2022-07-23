package services.meal

import utils.SimpleDate

import java.util.UUID

case class MealUpdate(
    mealId: UUID,
    date: SimpleDate,
    recipeId: UUID,
    amount: BigDecimal
)
