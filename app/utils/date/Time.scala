package utils.date

import cats.Order
import io.circe.{ Decoder, Encoder }

import java.time.LocalTime

import io.circe.generic.semiauto.{ deriveDecoder, deriveEncoder }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

import scala.util.Try

case class Time(
    hour: Int,
    minute: Int
)

object Time {

  implicit val encoder: Encoder[Time] = deriveEncoder[Time]

  // Duplicate work, but considered ok.
  implicit val decoder: Decoder[Time] = deriveDecoder[Time].emap { time =>
    Try(time.transformInto[LocalTime]).toEither.left
      .map(_.getMessage)
      .map(_ => time)
  }

  implicit val toJava: Transformer[Time, LocalTime] =
    time => LocalTime.of(time.hour, time.minute)

  implicit val fromJava: Transformer[LocalTime, Time] = localTime =>
    Time(
      hour = localTime.getHour,
      minute = localTime.getMinute
    )

  implicit val order: Order[Time] =
    Order.fromLessThan((t1, t2) => t1.transformInto[LocalTime].isBefore(t2.transformInto[LocalTime]))

}
