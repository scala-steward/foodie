package services.meal

import services.MealEntryId

case class MealEntryParameters(
    mealEntryId: MealEntryId,
    mealEntryPreCreation: MealEntryPreCreation
)
