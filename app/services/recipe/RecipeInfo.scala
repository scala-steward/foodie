package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.{ RecipeId, UserId }
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class RecipeInfo(
    id: RecipeId,
    name: String,
    description: Option[String]
)

object RecipeInfo {

  implicit val fromDB: Transformer[Tables.RecipeRow, RecipeInfo] =
    Transformer
      .define[Tables.RecipeRow, RecipeInfo]
      .withFieldComputed(_.id, _.id.transformInto[RecipeId])
      .buildTransformer

  implicit val toDB: Transformer[(RecipeInfo, UserId), Tables.RecipeRow] = {
    case (recipeInfo, userId) =>
      Tables.RecipeRow(
        id = recipeInfo.id.transformInto[UUID],
        userId = userId.transformInto[UUID],
        name = recipeInfo.name,
        description = recipeInfo.description
      )
  }

}
