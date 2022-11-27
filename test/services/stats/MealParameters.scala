package services.stats

import services.MealId
import services.meal.MealCreation

case class MealParameters(
    mealId: MealId,
    mealCreation: MealCreation,
    mealEntryParameters: List[MealEntryParameters]
)
