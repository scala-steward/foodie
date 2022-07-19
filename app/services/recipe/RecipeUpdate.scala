package services.recipe

import services.user.UserId
import shapeless.tag.@@

import java.util.UUID

case class RecipeUpdate(
    userId: UUID @@ UserId,
    id: UUID @@ RecipeId,
    name: String,
    description: Option[String]
)
