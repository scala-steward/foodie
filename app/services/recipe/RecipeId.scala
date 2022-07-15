package services.recipe

import io.scalaland.chimney.Transformer
import shapeless.tag
import shapeless.tag.@@

import java.util.UUID

sealed trait RecipeId

object RecipeId {

  implicit val fromUUID: Transformer[UUID, UUID @@ RecipeId] = tag[RecipeId](_)
  implicit val toUUID: Transformer[UUID @@ RecipeId, UUID]   = recipeId => recipeId: UUID

}
