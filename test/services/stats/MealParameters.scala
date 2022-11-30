package services.stats

import services.meal.MealCreation

case class MealParameters(
    mealCreation: MealCreation,
    mealEntryParameters: List[MealEntryParameters]
)
