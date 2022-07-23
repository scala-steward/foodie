package controllers.meal

import io.circe.generic.JsonCodec
import spire.algebra.Order
import spire.math.Interval

import java.time.LocalDate

@JsonCodec
case class RequestInterval(
    from: Option[LocalDate],
    to: Option[LocalDate]
)

object RequestInterval {

  implicit val localDateOrder: Order[LocalDate] = Order.by(_.toEpochDay)

  def toInterval(requestInterval: RequestInterval): Interval[LocalDate] =
    (requestInterval.from, requestInterval.to) match {
      case (Some(start), Some(end)) => Interval.closed(start, end)
      case (Some(start), _)         => Interval.atOrAbove(start)
      case (_, Some(end))           => Interval.atOrBelow(end)
      case (_, _)                   => Interval.all[LocalDate]
    }

}
