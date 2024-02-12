package services.meal

import db.{ MealEntryId, RecipeId }

case class MealEntryCreation(
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntryCreation {

  def create(id: MealEntryId, mealEntryCreation: MealEntryCreation): MealEntry =
    MealEntry(
      id = id,
      recipeId = mealEntryCreation.recipeId,
      numberOfServings = mealEntryCreation.numberOfServings
    )

}
