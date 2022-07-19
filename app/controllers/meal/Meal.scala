package controllers.meal

import io.circe.generic.JsonCodec

import java.time.{ LocalDate, LocalTime }
import java.util.UUID

@JsonCodec
case class Meal(
    id: UUID,
    date: LocalDate,
    time: LocalTime,
    name: Option[String],
    entries: Seq[MealEntry]
)
