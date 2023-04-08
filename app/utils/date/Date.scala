package utils.date

import cats.Order
import io.circe.{ Decoder, Encoder }

import java.time.{ LocalDate, LocalTime }
import io.circe.generic.semiauto.{ deriveDecoder, deriveEncoder }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._

import scala.util.Try

case class Date(
    year: Int,
    month: Int,
    day: Int
)

object Date {

  implicit val encoder: Encoder[Date] = deriveEncoder[Date]

  // Duplicate work, but considered ok.
  implicit val decoder: Decoder[Date] = deriveDecoder[Date].emap { date =>
    Try(
      date.transformInto[LocalDate]
    ).toEither.left
      .map(_.getMessage)
      .map(_ => date)
  }

  def parse(string: String): Option[Date] =
    Try(LocalDate.parse(string))
      .map(_.transformInto[Date])
      .toOption

  implicit val toJava: Transformer[Date, LocalDate] = date =>
    LocalDate.of(
      date.year,
      date.month,
      date.day
    )

  implicit val fromJava: Transformer[LocalDate, Date] = localDate =>
    Date(
      year = localDate.getYear,
      month = localDate.getMonthValue,
      day = localDate.getDayOfMonth
    )

  implicit val orderDate: Order[Date] =
    Order.fromLessThan((d1, d2) => d1.transformInto[LocalDate].isBefore(d2.transformInto[LocalDate]))

}
