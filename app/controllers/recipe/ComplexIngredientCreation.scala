package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.syntax._

@JsonCodec
case class ComplexIngredientCreation(
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredientCreation {

  implicit val toInternal
      : Transformer[ComplexIngredientCreation, services.complex.ingredient.ComplexIngredientCreation] = {
    complexIngredientCreation =>
      services.complex.ingredient.ComplexIngredientCreation(
        factor = complexIngredientCreation.factor,
        scalingMode = complexIngredientCreation.scalingMode.transformInto[services.complex.ingredient.ScalingMode]
      )
  }

}
