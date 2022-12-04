package services.recipe

import services.IngredientId

case class IngredientPreUpdate(
    amountUnit: AmountUnit
)

object IngredientPreUpdate {

  def toUpdate(
      ingredientId: IngredientId,
      ingredientPreUpdate: IngredientPreUpdate
  ): IngredientUpdate =
    IngredientUpdate(
      id = ingredientId,
      amountUnit = ingredientPreUpdate.amountUnit
    )

}
