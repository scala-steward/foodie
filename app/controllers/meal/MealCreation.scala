package controllers.meal

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.time.{ LocalDate, LocalTime }
import java.util.UUID
import utils.TransformerUtils.Implicits._

@JsonCodec
case class MealCreation(
    date: LocalDate,
    time: Option[LocalTime],
    name: Option[String],
    recipeId: UUID,
    amount: BigDecimal
)

object MealCreation {

  implicit val toInternal: Transformer[MealCreation, services.meal.MealCreation] =
    Transformer
      .define[MealCreation, services.meal.MealCreation]
      .buildTransformer

}
