package services.stats

import org.scalacheck.Prop
import org.scalacheck.Prop._

object PropUtil {

  def closeEnough(
      actual: Option[BigDecimal],
      expected: Option[BigDecimal],
      error: BigDecimal = BigDecimal(0.0000000001)
  ): Prop =
    (actual, expected) match {
      case (Some(av), Some(ev)) =>
        ((ev - av).abs < error) :| s"Distance between expected value $ev and actual value $av is smaller than $error"
      case (None, None) =>
        Prop.passed
      case _ => Prop.falsified :| s"Expected $expected, but got $actual"
    }

}
