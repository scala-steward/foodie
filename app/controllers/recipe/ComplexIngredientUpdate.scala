package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.syntax._

@JsonCodec
case class ComplexIngredientUpdate(
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredientUpdate {

  implicit val toInternal: Transformer[ComplexIngredientUpdate, services.complex.ingredient.ComplexIngredientUpdate] = {
    complexIngredientUpdate =>
      services.complex.ingredient.ComplexIngredientUpdate(
        factor = complexIngredientUpdate.factor,
        scalingMode = complexIngredientUpdate.scalingMode.transformInto[services.complex.ingredient.ScalingMode]
      )
  }

}
