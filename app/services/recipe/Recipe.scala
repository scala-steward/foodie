package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.user.UserId
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Recipe(
    id: RecipeId,
    name: String,
    description: Option[String],
    ingredients: Seq[Ingredient]
)

object Recipe {

  case class DBRepresentation(
      recipeRow: Tables.RecipeRow,
      ingredientRows: Seq[Tables.RecipeIngredientRow]
  )

  implicit val fromRepresentation: Transformer[DBRepresentation, Recipe] =
    Transformer
      .define[DBRepresentation, Recipe]
      .withFieldComputed(_.id, _.recipeRow.id.transformInto[RecipeId])
      .withFieldComputed(_.name, _.recipeRow.name)
      .withFieldComputed(_.description, _.recipeRow.description)
      .withFieldComputed(_.ingredients, _.ingredientRows.map(_.transformInto[Ingredient]))
      .buildTransformer

  implicit val toRepresentation: Transformer[(Recipe, UserId), DBRepresentation] = {
    case (recipe, userId) =>
      DBRepresentation(
        Tables.RecipeRow(
          id = recipe.id.transformInto[UUID],
          userId = userId.transformInto[UUID],
          name = recipe.name,
          description = recipe.description
        ),
        recipe.ingredients.map(i => (i, recipe.id).transformInto[Tables.RecipeIngredientRow])
      )
  }

}
