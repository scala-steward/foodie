package services.complex.ingredient

import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexIngredient(
    recipeId: RecipeId,
    complexFoodId: ComplexFoodId,
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredient {

  implicit val fromDB: Transformer[Tables.ComplexIngredientRow, ComplexIngredient] =
    row =>
      ComplexIngredient(
        recipeId = row.recipeId.transformInto[RecipeId],
        complexFoodId = row.complexFoodId.transformInto[ComplexFoodId],
        factor = row.factor,
        scalingMode = row.scalingMode.transformInto[ScalingMode]
      )

  implicit val toDB: Transformer[(ComplexIngredient, UserId), Tables.ComplexIngredientRow] = {
    case (complexIngredient, userId) =>
      Tables.ComplexIngredientRow(
        recipeId = complexIngredient.recipeId.transformInto[UUID],
        complexFoodId = complexIngredient.complexFoodId.transformInto[UUID],
        factor = complexIngredient.factor,
        scalingMode = complexIngredient.scalingMode.transformInto[String],
        userId = userId.transformInto[UUID]
      )
  }

}
