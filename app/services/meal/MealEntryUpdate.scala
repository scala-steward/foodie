package services.meal

import services.{ MealEntryId, RecipeId }

case class MealEntryUpdate(
    id: MealEntryId,
    recipeId: RecipeId,
    factor: BigDecimal
)

object MealEntryUpdate {

  def update(mealEntry: MealEntry, mealEntryUpdate: MealEntryUpdate): MealEntry =
    mealEntry.copy(
      factor = mealEntryUpdate.factor
    )

}
