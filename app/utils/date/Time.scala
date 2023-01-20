package utils.date

import cats.Order

import java.time.LocalTime
import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

@JsonCodec
case class Time(
    hour: Int,
    minute: Int
)

object Time {

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
