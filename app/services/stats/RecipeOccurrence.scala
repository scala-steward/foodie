package services.stats

import services.meal.Meal
import services.recipe.Recipe

case class RecipeOccurrence(
    recipe: Recipe,
    lastUsedInMeal: Option[Meal]
)
