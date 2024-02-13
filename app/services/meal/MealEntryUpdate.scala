package services.meal

case class MealEntryUpdate(
    numberOfServings: BigDecimal
)

object MealEntryUpdate {

  def update(mealEntry: MealEntry, mealEntryUpdate: MealEntryUpdate): MealEntry =
    mealEntry.copy(
      numberOfServings = mealEntryUpdate.numberOfServings
    )

}
