package services.stats

import services.FoodId
import services.nutrient.NutrientMap
import services.recipe.Recipe

case class RecipeNutrientMap(
    recipe: Recipe,
    nutrientMap: NutrientMap,
    foodIds: Set[FoodId]
)
