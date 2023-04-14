package util

import cats.syntax.order._
import io.scalaland.chimney.dsl._
import spire.math.Interval
import utils.date.{ Date, SimpleDate, Time }

import java.time.{ LocalDate, LocalTime }
import scala.concurrent.{ ExecutionContext, Future }

object DateUtil {

  def toInterval(from: Option[Date], to: Option[Date]): Interval[Date] =
    (from, to) match {
      case (Some(d1), Some(d2)) =>
        if (d1 <= d2)
          Interval.closed(d1, d2)
        else Interval.closed(d2, d1)
      case (Some(d1), None) => Interval.atOrAbove(d1)
      case (None, Some(d2)) => Interval.atOrBelow(d2)
      case _                => Interval.all[Date]
    }

  def now(implicit executionContext: ExecutionContext): Future[SimpleDate] = Future {
    SimpleDate(
      date = LocalDate.now().transformInto[Date],
      time = Some(LocalTime.now().transformInto[Time])
    )
  }

}
