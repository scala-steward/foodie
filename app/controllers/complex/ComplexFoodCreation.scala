package controllers.complex

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexFoodCreation(
    recipeId: UUID,
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal]
)

object ComplexFoodCreation {

  implicit val toInternal: Transformer[ComplexFoodCreation, services.complex.food.ComplexFoodCreation] =
    Transformer
      .define[ComplexFoodCreation, services.complex.food.ComplexFoodCreation]
      .buildTransformer

}
