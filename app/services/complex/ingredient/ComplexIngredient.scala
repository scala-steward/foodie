package services.complex.ingredient

import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ComplexIngredient(
    complexFoodId: ComplexFoodId,
    factor: BigDecimal,
    scalingMode: ScalingMode
)

object ComplexIngredient {

  implicit val fromDB: Transformer[Tables.ComplexIngredientRow, ComplexIngredient] =
    row =>
      ComplexIngredient(
        complexFoodId = row.complexFoodId.transformInto[ComplexFoodId],
        factor = row.factor,
        scalingMode = row.scalingMode.transformInto[ScalingMode]
      )

  case class TransformableToDB(
      userId: UserId,
      recipeId: RecipeId,
      complexIngredient: ComplexIngredient
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.ComplexIngredientRow] = { transformableToDB =>
    Tables.ComplexIngredientRow(
      recipeId = transformableToDB.recipeId.transformInto[UUID],
      complexFoodId = transformableToDB.complexIngredient.complexFoodId.transformInto[UUID],
      factor = transformableToDB.complexIngredient.factor,
      scalingMode = transformableToDB.complexIngredient.scalingMode.transformInto[String],
      userId = transformableToDB.userId.transformInto[UUID]
    )
  }

}
