package services.meal

import db.generated.Tables
import io.scalaland.chimney.Transformer
import services.recipe.RecipeId
import utils.IdUtils.Implicits._

case class MealEntry(
    id: MealEntryId,
    recipeId: RecipeId,
    factor: BigDecimal
)

object MealEntry {

  implicit val fromDB: Transformer[Tables.MealEntryRow, MealEntry] =
    Transformer
      .define[Tables.MealEntryRow, MealEntry]
      .buildTransformer

}
