package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.meal.MeasureId
import utils.IdUtils.Implicits._

case class Ingredient(
    id: IngredientId,
    foodId: FoodId,
    amountUnit: AmountUnit
)

object Ingredient {

  implicit val fromDB: Transformer[Tables.RecipeIngredientRow, Ingredient] =
    Transformer
      .define[Tables.RecipeIngredientRow, Ingredient]
      .withFieldComputed(_.id, _.id.transformInto[IngredientId])
      .withFieldComputed(_.foodId, _.foodNameId.transformInto[FoodId])
      .withFieldComputed(
        _.amountUnit,
        r =>
          AmountUnit(
            measureId = r.measureId.transformInto[MeasureId],
            factor = r.factor
          )
      )
      .buildTransformer

}
