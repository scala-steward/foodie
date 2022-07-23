package utils

import io.circe.generic.JsonCodec

import java.time.{ LocalDate, LocalTime }

@JsonCodec
case class SimpleDate(
    date: LocalDate,
    time: Option[LocalTime]
)
