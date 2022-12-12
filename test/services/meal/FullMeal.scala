package services.meal

case class FullMeal(
    meal: Meal,
    mealEntries: List[MealEntry]
)
