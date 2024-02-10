package services.complex.food

case class ComplexFoodUpdate(
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFoodUpdate {

  def update(complexFood: ComplexFoodIncoming, update: ComplexFoodUpdate): ComplexFoodIncoming =
    complexFood.copy(
      amountGrams = update.amountGrams,
      amountMilliLitres = update.amountMilliLitres
    )

}
