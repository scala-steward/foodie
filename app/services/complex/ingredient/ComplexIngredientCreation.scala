package services.complex.ingredient

import db.ComplexFoodId

case class ComplexIngredientCreation(
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredientCreation {

  def create(
      complexFoodId: ComplexFoodId,
      complexIngredientCreation: ComplexIngredientCreation
  ): ComplexIngredient =
    ComplexIngredient(
      complexFoodId = complexFoodId,
      factor = complexIngredientCreation.factor,
      scalingMode = complexIngredientCreation.scalingMode
    )

}
