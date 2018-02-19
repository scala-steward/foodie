package base

import physical.PhysicalAmount.Implicits._
import physical._
import spire.implicits._
import spire.math.Numeric

trait Amount[N] {

  implicit val numeric: Numeric[N]

  def toMass: Mass[N, _]

}

abstract class ByVolume[N: Numeric, P: Prefix] extends Amount[N] {

  override val numeric: Numeric[N] = implicitly[Numeric[N]]

  def weightOfMilliLitre: Mass[N, P]

  def litres: PhysicalAmount[N, _]

  override def toMass: Mass[N, _] = {
    val actual = litres.absolute *: weightOfMilliLitre.amount
    Mass(actual).normalised
  }
}