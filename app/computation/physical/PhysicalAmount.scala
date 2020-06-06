package computation.physical

import algebra.ring.Ring
import computation.base.math.LeftModuleUtil.Implicits._
import computation.base.math.LeftModuleUtil.LeftModuleSelf
import spire.algebra.LeftModule
import spire.syntax.vectorSpace._

case class PhysicalAmount[N](value: N)

object PhysicalAmount {

  object Implicits {

    implicit def physicalAmountLeftModule[L: LeftModuleSelf]: LeftModule[PhysicalAmount[L], L] = new LeftModule[PhysicalAmount[L], L] {
      override def scalar: Ring[L] = Ring[L]

      override def timesl(r: L, v: PhysicalAmount[L]): PhysicalAmount[L] = v.copy(value = r * v.value)

      override def negate(x: PhysicalAmount[L]): PhysicalAmount[L] = x.copy(value = scalar.negate(x.value))

      override def zero: PhysicalAmount[L] = PhysicalAmount(LeftModuleSelf[L].zero)

      override def plus(x: PhysicalAmount[L], y: PhysicalAmount[L]): PhysicalAmount[L] =
        PhysicalAmount(scalar.plus(x.value , y.value))
    }

  }

}