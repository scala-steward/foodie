package services.meal

import db.RecipeId

case class MealEntryUpdate(
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntryUpdate {

  def update(mealEntry: MealEntry, mealEntryUpdate: MealEntryUpdate): MealEntry =
    mealEntry.copy(
      numberOfServings = mealEntryUpdate.numberOfServings
    )

}
