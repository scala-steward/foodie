package services.meal

import services.recipe.RecipeId
import utils.SimpleDate

case class MealCreation(
    date: SimpleDate,
    name: Option[String],
    recipeId: RecipeId,
    amount: BigDecimal
)

object MealCreation {

  def create(id: MealId, mealCreation: MealCreation): Meal =
    Meal(
      id = id,
      date = mealCreation.date.date,
      time = mealCreation.date.time,
      name = mealCreation.name,
      entries = Seq.empty
    )

}
