package services.complex.ingredient

case class ComplexIngredientUpdate(
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredientUpdate {

  def update(
      complexIngredient: ComplexIngredient,
      complexIngredientUpdate: ComplexIngredientUpdate
  ): ComplexIngredient =
    complexIngredient.copy(
      factor = complexIngredientUpdate.factor,
      scalingMode = complexIngredientUpdate.scalingMode
    )

}
