package controllers.meal

import java.time.Instant
import java.util.UUID

case class MealUpdate(
    mealId: UUID,
    date: Instant,
    recipeId: UUID,
    amount: BigDecimal
)
