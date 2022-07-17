package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.IdUtils.Implicits._

import java.util.UUID

@JsonCodec
case class IngredientUpdate(
    recipeId: UUID,
    ingredientId: UUID,
    amountUnit: AmountUnit
)

object IngredientUpdate {

  implicit val toInternal: Transformer[IngredientUpdate, services.recipe.IngredientUpdate] =
    Transformer
      .define[IngredientUpdate, services.recipe.IngredientUpdate]
      .buildTransformer

}
