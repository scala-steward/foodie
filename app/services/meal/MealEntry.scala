package services.meal

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.{ MealEntryId, MealId, RecipeId }
import utils.TransformerUtils.Implicits._

import java.util.UUID

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

  implicit val toDB: Transformer[(MealEntry, MealId), Tables.MealEntryRow] = {
    case (mealEntry, mealId) =>
      Tables.MealEntryRow(
        id = mealEntry.id.transformInto[UUID],
        mealId = mealId.transformInto[UUID],
        recipeId = mealEntry.recipeId.transformInto[UUID],
        factor = mealEntry.factor
      )
  }

}
