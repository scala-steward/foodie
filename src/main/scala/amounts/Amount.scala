package amounts

import base.Mass
import physical.Prefix.Syntax._
import physical.{Milli, PhysicalAmount, Prefix}
import spire.implicits._
import spire.math.Numeric
import PhysicalAmount.Implicits._

import scalaz.Tag

sealed trait Amount[N] {
  def toMass[P: Prefix]: Mass[N, P]
}

abstract class ByVolume[N: Numeric] extends Amount[N] {

  def weightOfMillilitre[P: Prefix]: Mass[N, P]

  def litres: PhysicalAmount[N, _]

  override def toMass[P: Prefix]: Mass[N, P] = {
    val actual = Tag.unwrap(litres.rescale[Milli].relative) *: weightOfMillilitre[P].amount
    Mass(actual)
  }
}



trait Weighted[N] extends Amount[N]


