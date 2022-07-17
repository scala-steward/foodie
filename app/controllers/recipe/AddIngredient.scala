package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.IdUtils.Implicits._

import java.util.UUID

@JsonCodec
case class AddIngredient(
    recipeId: UUID,
    foodId: Int,
    amountUnit: AmountUnit
)

object AddIngredient {

  implicit val toInternal: Transformer[AddIngredient, services.recipe.AddIngredient] =
    Transformer
      .define[AddIngredient, services.recipe.AddIngredient]
      .buildTransformer

}
