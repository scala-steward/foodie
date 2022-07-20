package services.meal

import services.recipe.RecipeId

import java.time.{ LocalDate, LocalTime }

case class MealCreation(
    date: LocalDate,
    time: Option[LocalTime],
    name: Option[String],
    recipeId: RecipeId,
    amount: BigDecimal
)

object MealCreation {

  def create(id: MealId, mealCreation: MealCreation): Meal =
    Meal(
      id = id,
      date = mealCreation.date,
      time = mealCreation.time,
      name = mealCreation.name,
      entries = Seq.empty
    )

}
