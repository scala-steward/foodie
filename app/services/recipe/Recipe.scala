package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class Recipe(
    id: UUID @@ RecipeId,
    name: String,
    description: Option[String]
)
