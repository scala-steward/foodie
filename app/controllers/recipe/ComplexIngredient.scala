package controllers.recipe

import db.ComplexFoodId
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexIngredient(
    complexFoodId: UUID,
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredient {

  implicit val fromInternal: Transformer[services.complex.ingredient.ComplexIngredient, ComplexIngredient] =
    Transformer
      .define[services.complex.ingredient.ComplexIngredient, ComplexIngredient]
      .buildTransformer

  implicit val toInternal: Transformer[ComplexIngredient, services.complex.ingredient.ComplexIngredient] = {
    complexIngredient =>
      services.complex.ingredient.ComplexIngredient(
        complexFoodId = complexIngredient.complexFoodId.transformInto[ComplexFoodId],
        factor = complexIngredient.factor,
        scalingMode = complexIngredient.scalingMode.transformInto[services.complex.ingredient.ScalingMode]
      )
  }

}
