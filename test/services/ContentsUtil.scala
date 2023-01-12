package services

import db.{ MealId, RecipeId, UserId }
import services.meal.{ FullMeal, Meal, MealEntry }
import services.recipe.{ FullRecipe, Ingredient, Recipe }

object ContentsUtil {

  object Ingredient {

    def from(fullRecipe: FullRecipe): Seq[(RecipeId, Ingredient)] =
      fullRecipe.ingredients.map(fullRecipe.recipe.id -> _)

  }

  object Meal {

    def from(userId: UserId, meals: Seq[Meal]): Seq[(UserId, Meal)] =
      meals.map(userId -> _)

  }

  object MealEntry {

    def from(fullMeal: FullMeal): Seq[(MealId, MealEntry)] =
      fullMeal.mealEntries.map(fullMeal.meal.id -> _)

  }

  object Recipe {

    def from(userId: UserId, recipes: Seq[Recipe]): Seq[(UserId, Recipe)] =
      recipes.map(userId -> _)

  }

}
