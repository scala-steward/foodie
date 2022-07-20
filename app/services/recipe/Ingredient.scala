package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.IdUtils.Implicits._

import java.util.UUID

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

  implicit val toDB: Transformer[(Ingredient, RecipeId), Tables.RecipeIngredientRow] = {
    case (ingredient, recipeId) =>
      Tables.RecipeIngredientRow(
        id = ingredient.id.transformInto[UUID],
        recipeId = recipeId.transformInto[UUID],
        foodNameId = ingredient.foodId.transformInto[Int],
        measureId = ingredient.amountUnit.measureId.transformInto[Int],
        factor = ingredient.amountUnit.factor
      )
  }

}
