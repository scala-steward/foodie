package services.recipe

import db.{ FoodId, IngredientId }

case class IngredientCreation(
    foodId: FoodId,
    amountUnit: AmountUnit
)

object IngredientCreation {

  def create(id: IngredientId, ingredientCreation: IngredientCreation): Ingredient =
    Ingredient(
      id = id,
      foodId = ingredientCreation.foodId,
      amountUnit = ingredientCreation.amountUnit
    )

}
