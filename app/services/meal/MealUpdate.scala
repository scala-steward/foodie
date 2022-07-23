package services.meal

import services.recipe.RecipeId
import utils.SimpleDate

case class MealUpdate(
    id: MealId,
    date: SimpleDate,
    name: Option[String],
    recipeId: RecipeId
)
