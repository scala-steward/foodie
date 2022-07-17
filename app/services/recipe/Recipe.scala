package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.user.UserId
import shapeless.tag.@@
import utils.IdUtils.Implicits._

import java.util.UUID

case class Recipe(
    id: UUID @@ RecipeId,
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
      .withFieldComputed(_.id, _.recipeRow.id.transformInto[UUID @@ RecipeId])
      .withFieldComputed(_.name, _.recipeRow.name)
      .withFieldComputed(_.description, _.recipeRow.description)
      .withFieldComputed(_.ingredients, _.ingredientRows.map(_.transformInto[Ingredient]))
      .buildTransformer

}
