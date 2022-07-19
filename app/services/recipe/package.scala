package services

import shapeless.tag.@@

import java.util.UUID

package object recipe {

  sealed trait RecipeTag

  type RecipeId = UUID @@ RecipeTag

  sealed trait IngredientTag

  type IngredientId = UUID @@ IngredientTag

  sealed trait FoodTag

  type FoodId = Int @@ FoodTag
}
