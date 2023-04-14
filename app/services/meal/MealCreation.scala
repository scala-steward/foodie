package services.meal

import db.MealId
import utils.date.SimpleDate

case class MealCreation(
    date: SimpleDate,
    name: Option[String]
)

object MealCreation {

  def create(id: MealId, mealCreation: MealCreation): Meal =
    Meal(
      id = id,
      date = mealCreation.date,
      name = mealCreation.name.map(_.trim)
    )

}
