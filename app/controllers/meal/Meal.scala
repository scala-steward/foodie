package controllers.meal

import io.circe.generic.JsonCodec
import utils.SimpleDate

import java.util.UUID

@JsonCodec
case class Meal(
    id: UUID,
    date: SimpleDate,
    name: Option[String],
    entries: Seq[MealEntry]
)
