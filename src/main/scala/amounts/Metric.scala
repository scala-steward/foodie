package amounts

import base.{Ingredient, Mass}
import physical.Prefix
import spire.math.Numeric

import scala.reflect.ClassTag

case class Metric[N: Numeric](mass: Mass[N, _ <: Prefix],
                              override val ingredient: Ingredient[N]) extends Weighted[N] {
  override def toMass[P <: Prefix: ClassTag]: Mass[N, P] = Mass(mass.amount.rescale[P])
}
