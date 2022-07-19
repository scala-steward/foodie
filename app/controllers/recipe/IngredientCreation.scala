package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.IdUtils.Implicits._

import java.util.UUID

@JsonCodec
case class IngredientCreation(
    recipeId: UUID,
    foodId: Int,
    amountUnit: AmountUnit
)

object IngredientCreation {

  implicit val toInternal: Transformer[IngredientCreation, services.recipe.IngredientCreation] =
    Transformer
      .define[IngredientCreation, services.recipe.IngredientCreation]
      .buildTransformer

}
