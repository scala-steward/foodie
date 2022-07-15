package services.recipe

import io.scalaland.chimney.Transformer
import shapeless.tag
import shapeless.tag.@@

import java.util.UUID

sealed trait IngredientId

object IngredientId {

  implicit val fromUUID: Transformer[UUID, UUID @@ IngredientId] = tag[IngredientId](_)
  implicit val toUUID: Transformer[UUID @@ IngredientId, UUID]   = ingredientId => ingredientId: UUID

}
