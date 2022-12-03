package services.meal

case class MealParameters(
    mealCreation: MealCreation,
    mealEntryParameters: List[MealEntryParameters]
)
