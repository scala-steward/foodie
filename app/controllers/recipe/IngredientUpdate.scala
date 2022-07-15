package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID

@JsonCodec
case class IngredientUpdate(
    recipeId: UUID,
    ingredientId: UUID,
    amount: BigDecimal
)

object IngredientUpdate {

  implicit val toDB: Transformer[IngredientUpdate, services.recipe.IngredientUpdate] =
    Transformer
      .define[IngredientUpdate, services.recipe.IngredientUpdate]
      .buildTransformer

}
