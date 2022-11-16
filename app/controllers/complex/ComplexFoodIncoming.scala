package controllers.complex

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexFoodIncoming(
    recipeId: UUID,
    amount: BigDecimal,
    unit: ComplexFoodUnit
)

object ComplexFoodIncoming {

  implicit val toInternal: Transformer[ComplexFoodIncoming, services.complex.food.ComplexFoodIncoming] =
    Transformer
      .define[ComplexFoodIncoming, services.complex.food.ComplexFoodIncoming]
      .buildTransformer

}
