package utils

import cats.data.NonEmptyList
import spire.algebra.Field
import spire.compat._
import spire.algebra.Order
import spire.syntax.field._

object MathUtil {

  def median[A: Order: Field](neList: NonEmptyList[A]): A = {
    val sortedList = neList.toList.sorted
    val size       = neList.size
    if (size % 2 != 0)
      sortedList((size - 1) / 2)
    else {
      val half = size / 2
      (sortedList(half - 1) + sortedList(half)) / 2
    }
  }

}
