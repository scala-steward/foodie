package services.recipe

import db.generated.Tables
import db.{ RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Recipe(
    id: RecipeId,
    name: String,
    description: Option[String],
    numberOfServings: BigDecimal,
    servingSize: Option[String]
)

object Recipe {

  implicit val fromDB: Transformer[Tables.RecipeRow, Recipe] =
    Transformer
      .define[Tables.RecipeRow, Recipe]
      .buildTransformer

  case class TransformableToDB(
      userId: UserId,
      recipe: Recipe
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.RecipeRow] = { transformableToDB =>
    Tables.RecipeRow(
      id = transformableToDB.recipe.id.transformInto[UUID],
      userId = transformableToDB.userId.transformInto[UUID],
      name = transformableToDB.recipe.name,
      description = transformableToDB.recipe.description,
      numberOfServings = transformableToDB.recipe.numberOfServings,
      servingSize = transformableToDB.recipe.servingSize
    )

  }

}
