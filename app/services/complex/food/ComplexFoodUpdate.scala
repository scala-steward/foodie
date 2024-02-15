package services.complex.food

case class ComplexFoodUpdate(
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFoodUpdate {

  def update(complexFood: ComplexFood, update: ComplexFoodUpdate): ComplexFood =
    complexFood.copy(
      amountGrams = update.amountGrams,
      amountMilliLitres = update.amountMilliLitres
    )

}
