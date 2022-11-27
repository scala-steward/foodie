package services.stats

import services.MealEntryId

case class MealEntryParameters(
    mealEntryId: MealEntryId,
    mealEntryPreCreation: MealEntryPreCreation
)
