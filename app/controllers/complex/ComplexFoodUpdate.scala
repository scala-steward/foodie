package controllers.complex

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec
case class ComplexFoodUpdate(
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFoodUpdate {

  implicit val toInternal: Transformer[ComplexFoodUpdate, services.complex.food.ComplexFoodUpdate] =
    Transformer
      .define[ComplexFoodUpdate, services.complex.food.ComplexFoodUpdate]
      .buildTransformer

}
