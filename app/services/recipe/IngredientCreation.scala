package services.recipe

import db.generated.Tables
import io.scalaland.chimney.dsl._
import utils.IdUtils.Implicits._

import java.util.UUID

case class IngredientCreation(
    recipeId: RecipeId,
    foodId: FoodId,
    amountUnit: AmountUnit
)

object IngredientCreation {

  def create(id: IngredientId, ingredientCreation: IngredientCreation): Tables.RecipeIngredientRow =
    Tables.RecipeIngredientRow(
      id = id.transformInto[UUID],
      recipeId = ingredientCreation.recipeId.transformInto[UUID],
      foodNameId = ingredientCreation.foodId.transformInto[Int],
      measureId = ingredientCreation.amountUnit.measureId.transformInto[Int],
      factor = ingredientCreation.amountUnit.factor
    )

}
