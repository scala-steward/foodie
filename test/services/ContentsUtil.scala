package services

import db.{ MealId, RecipeId, ReferenceMapId, UserId }
import services.complex.food.ComplexFoodIncoming
import services.complex.ingredient.ComplexIngredient
import services.meal.{ FullMeal, Meal, MealEntry }
import services.recipe.{ FullRecipe, Ingredient, Recipe }
import services.reference.{ FullReferenceMap, ReferenceEntry, ReferenceMap }

object ContentsUtil {

  object ComplexFood {

    def from(userId: UserId, complexFoods: Seq[ComplexFoodIncoming]): Seq[(UserId, RecipeId, ComplexFoodIncoming)] =
      complexFoods.map(complexFood => (userId, complexFood.recipeId, complexFood))

  }

  object ComplexIngredient {

    def from(
        userId: UserId,
        recipeId: RecipeId,
        complexIngredients: Seq[ComplexIngredient]
    ): Seq[(UserId, RecipeId, ComplexIngredient)] =
      complexIngredients.map(complexIngredient => (userId, recipeId, complexIngredient))

  }

  object Ingredient {

    def from(userId: UserId, fullRecipe: FullRecipe): Seq[(UserId, RecipeId, Ingredient)] =
      fullRecipe.ingredients.map(ingredient => (userId, fullRecipe.recipe.id, ingredient))

  }

  object Meal {

    def from(userId: UserId, meals: Seq[Meal]): Seq[(UserId, Meal)] =
      meals.map(userId -> _)

  }

  object MealEntry {

    def from(userId: UserId, fullMeal: FullMeal): Seq[(UserId, MealId, MealEntry)] =
      fullMeal.mealEntries.map(entry => (userId, fullMeal.meal.id, entry))

  }

  object Recipe {

    def from(userId: UserId, recipes: Seq[Recipe]): Seq[(UserId, Recipe)] =
      recipes.map(userId -> _)

  }

  object ReferenceEntry {

    def from(userId: UserId, fullReferenceMap: FullReferenceMap): Seq[(UserId, ReferenceMapId, ReferenceEntry)] =
      fullReferenceMap.referenceEntries.map(entry => (userId, fullReferenceMap.referenceMap.id, entry))

  }

  object ReferenceMap {

    def from(userId: UserId, referenceMaps: Seq[ReferenceMap]): Seq[(UserId, ReferenceMap)] =
      referenceMaps.map(userId -> _)

  }

}
