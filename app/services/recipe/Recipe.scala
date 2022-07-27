package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.{ RecipeId, UserId }
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Recipe(
    recipeInfo: RecipeInfo,
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
      .withFieldComputed(_.recipeInfo, _.recipeRow.transformInto[RecipeInfo])
      .withFieldComputed(_.ingredients, _.ingredientRows.map(_.transformInto[Ingredient]))
      .buildTransformer

  implicit val toRepresentation: Transformer[(Recipe, UserId), DBRepresentation] = {
    case (recipe, userId) =>
      DBRepresentation(
        Tables.RecipeRow(
          id = recipe.recipeInfo.id.transformInto[UUID],
          userId = userId.transformInto[UUID],
          name = recipe.recipeInfo.name,
          description = recipe.recipeInfo.description
        ),
        recipe.ingredients.map(i => (i, recipe.recipeInfo.id).transformInto[Tables.RecipeIngredientRow])
      )
  }

}
