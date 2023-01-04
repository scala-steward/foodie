package services.stats

import db.FoodId
import services.nutrient.NutrientMap
import services.recipe.Recipe

case class RecipeNutrientMap(
    recipe: Recipe,
    nutrientMap: NutrientMap,
    foodIds: Set[FoodId]
)
