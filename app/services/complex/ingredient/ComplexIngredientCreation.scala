package services.complex.ingredient

import db.ComplexFoodId

case class ComplexIngredientCreation(
    complexFoodId: ComplexFoodId,
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredientCreation {

  def create(
      complexIngredientCreation: ComplexIngredientCreation
  ): ComplexIngredient =
    ComplexIngredient(
      complexFoodId = complexIngredientCreation.complexFoodId,
      factor = complexIngredientCreation.factor,
      scalingMode = complexIngredientCreation.scalingMode
    )

}
