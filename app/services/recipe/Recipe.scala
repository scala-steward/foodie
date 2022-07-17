package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import shapeless.tag.@@

import java.util.UUID

case class Recipe(
    id: UUID @@ RecipeId,
    name: String,
    description: Option[String],
    ingredients: Vector[Ingredient]
)

object Recipe {}
