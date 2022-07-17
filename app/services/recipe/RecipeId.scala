package services.recipe

import utils.IdOf

sealed trait RecipeId

object RecipeId extends IdOf[FoodId]
