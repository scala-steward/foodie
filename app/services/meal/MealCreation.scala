package services.meal

import services.recipe.RecipeId

import java.time.{ LocalDate, LocalTime }

case class MealCreation(
    date: LocalDate,
    time: LocalTime,
    recipeId: RecipeId,
    amount: BigDecimal
)
