package util

import spire.math.Interval
import utils.date.Date
import cats.syntax.order._

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

}
