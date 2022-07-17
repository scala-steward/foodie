package controllers.recipe

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class Recipe(
    id: UUID,
    //todo: Without refactoring there is the implicit assumption that all recipeIds are the same
    ingredients: Seq[Ingredient]
)
