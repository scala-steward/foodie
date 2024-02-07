package services.meal

import db.{ MealEntryId, MealId, RecipeId }

case class MealEntryUpdate(
    mealId: MealId,
    id: MealEntryId,
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntryUpdate {

  def update(mealEntry: MealEntry, mealEntryUpdate: MealEntryUpdate): MealEntry =
    mealEntry.copy(
      numberOfServings = mealEntryUpdate.numberOfServings
    )

}
