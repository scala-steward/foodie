package services.recipe

import db.generated.Tables
import shapeless.tag.@@
import io.scalaland.chimney.dsl._
import services.user.UserId
import utils.IdUtils.Implicits._

import java.util.UUID

case class AddIngredient(
    userId: UUID @@ UserId,
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
