package services.meal

import db.generated.Tables
import io.scalaland.chimney.Transformer
import services.recipe.RecipeId
import shapeless.tag.@@
import utils.IdUtils.Implicits._

import java.util.UUID

case class MealEntry(
    id: UUID @@ MealEntryId,
    recipeId: UUID @@ RecipeId,
    factor: BigDecimal
)

object MealEntry {

  implicit val fromDB: Transformer[Tables.MealEntryRow, MealEntry] =
    Transformer
      .define[Tables.MealEntryRow, MealEntry]
      .buildTransformer

}
