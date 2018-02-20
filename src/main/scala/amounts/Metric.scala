package amounts

import base.Mass
import physical.Prefix
import spire.math.Numeric

case class Metric[N: Numeric](mass: Mass[N, _]) extends Weighted[N] {
  override def toMass[P: Prefix]: Mass[N, P] = Mass(mass.amount.rescale[P])
}
