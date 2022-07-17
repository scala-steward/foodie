package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import shapeless.tag.@@
import utils.IdUtils.Implicits._

import java.util.UUID

case class Ingredient(
    id: UUID @@ IngredientId,
    foodId: Int @@ FoodId,
    amountUnit: AmountUnit
)

object Ingredient {

  implicit val fromDB: Transformer[Tables.RecipeIngredientRow, Ingredient] =
    Transformer
      .define[Tables.RecipeIngredientRow, Ingredient]
      .withFieldComputed(_.id, _.id.transformInto[UUID @@ IngredientId])
      .withFieldComputed(_.foodId, _.foodNameId.transformInto[Int @@ FoodId])
      .withFieldComputed(
        _.amountUnit,
        r =>
          AmountUnit(
            measureId = r.measureId.transformInto[Int @@ MeasureId],
            factor = r.amount
          )
      )
      .buildTransformer

}
