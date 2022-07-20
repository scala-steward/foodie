package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

import java.util.UUID

@JsonCodec
case class MealEntryUpdate(
    id: UUID,
    recipeId: UUID,
    factor: BigDecimal
)

object MealEntryUpdate {

  implicit val toInternal: Transformer[MealEntryUpdate, services.meal.MealEntryUpdate] = {
    Transformer
      .define[MealEntryUpdate, services.meal.MealEntryUpdate]
      .buildTransformer
  }

}
