package services

import db.{ MealId, RecipeId, ReferenceMapId, UserId }
import services.complex.food.ComplexFoodIncoming
import services.complex.ingredient.ComplexIngredient
import services.meal.{ FullMeal, Meal, MealEntry }
import services.recipe.{ FullRecipe, Ingredient, Recipe }
import services.reference.{ FullReferenceMap, ReferenceEntry, ReferenceMap }

object ContentsUtil {

  object ComplexFood {

    def from(complexFoods: Seq[ComplexFoodIncoming]): Seq[(RecipeId, ComplexFoodIncoming)] =
      complexFoods.map(complexFood => complexFood.recipeId -> complexFood)

  }

  object ComplexIngredient {

    def from(recipeId: RecipeId, complexIngredients: Seq[ComplexIngredient]): Seq[(RecipeId, ComplexIngredient)] =
      complexIngredients.map(recipeId -> _)

  }

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

  object ReferenceEntry {

    def from(fullReferenceMap: FullReferenceMap): Seq[(ReferenceMapId, ReferenceEntry)] =
      fullReferenceMap.referenceEntries.map(fullReferenceMap.referenceMap.id -> _)

  }

  object ReferenceMap {

    def from(userId: UserId, referenceMaps: Seq[ReferenceMap]): Seq[(UserId, ReferenceMap)] =
      referenceMaps.map(userId -> _)

  }

}
