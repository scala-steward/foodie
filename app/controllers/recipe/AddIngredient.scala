package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID

@JsonCodec
case class AddIngredient(
    recipeId: UUID,
    ingredientId: Int,
    amount: BigDecimal
)

object AddIngredient {

  implicit val toDB: Transformer[AddIngredient, services.recipe.AddIngredient] =
    Transformer
      .define[AddIngredient, services.recipe.AddIngredient]
      .buildTransformer

}
