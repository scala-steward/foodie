package utils.date

import cats.Order
import cats.syntax.order._
import io.circe.generic.JsonCodec
import io.scalaland.chimney.dsl._

import java.time.{ LocalDate, LocalTime }

@JsonCodec
case class SimpleDate(
    date: Date,
    time: Option[Time]
)

object SimpleDate {

  implicit val order: Order[SimpleDate] =
    Order.fromLessThan((sd1, sd2) => sd1.date < sd2.date || (sd1.date == sd2.date && sd1.time < sd2.time))

  def toPrettyString(simpleDate: SimpleDate): String = {
    val dateString = simpleDate.date.transformInto[LocalDate].toString.replace("-", ".")
    val timeString = simpleDate.time.map(_.transformInto[LocalTime].toString)
    List(
      Some(dateString),
      timeString
    ).flatten.mkString(" ")
  }

}
