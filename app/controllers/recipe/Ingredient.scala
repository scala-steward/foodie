package controllers.recipe

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.IdUtils.Implicits._

import java.util.UUID

@JsonCodec
case class Ingredient(
    id: UUID,
    foodId: Int,
    amount: Amount
)

object Ingredient {

  implicit val fromInternal: Transformer[services.recipe.Ingredient, Ingredient] =
    Transformer
      .define[services.recipe.Ingredient, Ingredient]
      .buildTransformer

  implicit val toInternal: Transformer[Ingredient, services.recipe.Ingredient] =
    Transformer
      .define[Ingredient, services.recipe.Ingredient]
      .buildTransformer

}
