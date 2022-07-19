package services.recipe

import db.generated.Tables
import io.scalaland.chimney.dsl._
import utils.IdUtils.Implicits._

import java.util.UUID

case class AddIngredient(
    recipeId: RecipeId,
    foodId: FoodId,
    amountUnit: AmountUnit
)

object AddIngredient {

  def create(id: IngredientId, addIngredient: AddIngredient): Tables.RecipeIngredientRow =
    Tables.RecipeIngredientRow(
      id = id.transformInto[UUID],
      recipeId = addIngredient.recipeId.transformInto[UUID],
      foodNameId = addIngredient.foodId.transformInto[Int],
      measureId = addIngredient.amountUnit.measureId.transformInto[Int],
      factor = addIngredient.amountUnit.factor
    )

}
