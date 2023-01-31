package controllers.complex

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexFood(
    recipeId: UUID,
    amountGrams: BigDecimal,
    amountMilliLitres: Option[BigDecimal],
    name: String,
    description: Option[String]
)

object ComplexFood {

  implicit val fromInternal: Transformer[services.complex.food.ComplexFood, ComplexFood] =
    Transformer
      .define[services.complex.food.ComplexFood, ComplexFood]
      .buildTransformer

}
