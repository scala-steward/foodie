package services.recipe

import db.generated.Tables
import db.{ FoodId, IngredientId, MeasureId, RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import utils.TransformerUtils.Implicits._

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
            measureId = r.measureId.map(_.transformInto[MeasureId]),
            factor = r.factor
          )
      )
      .buildTransformer

  case class TransformableToDB(
      userId: UserId,
      recipeId: RecipeId,
      ingredient: Ingredient
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.RecipeIngredientRow] = { transformableToDB =>
    Tables.RecipeIngredientRow(
      id = transformableToDB.ingredient.id.transformInto[UUID],
      recipeId = transformableToDB.recipeId.transformInto[UUID],
      foodNameId = transformableToDB.ingredient.foodId.transformInto[Int],
      measureId = transformableToDB.ingredient.amountUnit.measureId.map(_.transformInto[Int]),
      factor = transformableToDB.ingredient.amountUnit.factor,
      userId = transformableToDB.userId.transformInto[UUID]
    )
  }

}
