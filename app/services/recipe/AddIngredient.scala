package services.recipe

import db.generated.Tables
import io.scalaland.chimney.dsl._
import shapeless.tag.@@
import utils.IdUtils.Implicits._

import java.util.UUID

case class AddIngredient(
    recipeId: UUID @@ RecipeId,
    foodId: Int @@ FoodId,
    amountUnit: AmountUnit
)

object AddIngredient {

  def create(id: UUID @@ IngredientId, addIngredient: AddIngredient): Tables.RecipeIngredientRow =
    Tables.RecipeIngredientRow(
      id = id.transformInto[UUID],
      recipeId = addIngredient.recipeId.transformInto[UUID],
      foodNameId = addIngredient.foodId.transformInto[Int],
      measureId = addIngredient.amountUnit.measureId.transformInto[Int],
      factor = addIngredient.amountUnit.factor
    )

}
