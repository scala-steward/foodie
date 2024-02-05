package services.meal

import db.generated.Tables
import db.{ MealEntryId, MealId, RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class MealEntry(
    id: MealEntryId,
    recipeId: RecipeId,
    numberOfServings: BigDecimal
)

object MealEntry {

  implicit val fromDB: Transformer[Tables.MealEntryRow, MealEntry] =
    Transformer
      .define[Tables.MealEntryRow, MealEntry]
      .buildTransformer

  implicit val toDB: Transformer[(MealEntry, MealId, UserId), Tables.MealEntryRow] = {
    case (mealEntry, mealId, userId) =>
      Tables.MealEntryRow(
        id = mealEntry.id.transformInto[UUID],
        mealId = mealId.transformInto[UUID],
        recipeId = mealEntry.recipeId.transformInto[UUID],
        numberOfServings = mealEntry.numberOfServings,
        userId = userId.transformInto[UUID]
      )
  }

}
