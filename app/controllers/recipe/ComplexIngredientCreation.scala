package controllers.recipe

import db.ComplexFoodId
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class ComplexIngredientCreation(
    complexFoodId: UUID,
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredientCreation {

  implicit val toInternal
      : Transformer[ComplexIngredientCreation, services.complex.ingredient.ComplexIngredientCreation] =
    complexIngredientCreation =>
      services.complex.ingredient.ComplexIngredientCreation(
        complexFoodId = complexIngredientCreation.complexFoodId.transformInto[ComplexFoodId],
        factor = complexIngredientCreation.factor,
        scalingMode = complexIngredientCreation.scalingMode.transformInto[services.complex.ingredient.ScalingMode]
      )

}
