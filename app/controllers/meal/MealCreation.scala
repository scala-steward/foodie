package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.time.{ LocalDate, LocalTime }
import java.util.UUID
import utils.IdUtils.Implicits._

@JsonCodec
case class MealCreation(
    date: LocalDate,
    time: LocalTime,
    recipeId: UUID,
    amount: BigDecimal
)

object MealCreation {

  implicit val toInternal: Transformer[MealCreation, services.meal.MealCreation] =
    Transformer
      .define[MealCreation, services.meal.MealCreation]
      .buildTransformer

}
