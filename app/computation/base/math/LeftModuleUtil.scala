package computation.base.math

import spire.algebra.{LeftModule, Ring}
import spire.syntax.ring._

object LeftModuleUtil {

  type LeftModuleSelf[L] = LeftModule[L, L]

  object LeftModuleSelf {
    def apply[L](implicit leftModuleSelf: LeftModuleSelf[L]): LeftModuleSelf[L] = leftModuleSelf
  }

  object Implicits {
    implicit def leftModuleAsRing[L](implicit leftModule: LeftModule[L, L]): Ring[L] = new Ring[L] {
      override def one: L = leftModule.scalar.one

      override def negate(x: L): L = leftModule.scalar.negate(x)

      override def zero: L = leftModule.scalar.zero

      override def plus(x: L, y: L): L = leftModule.scalar.plus(x, y)

      override def times(x: L, y: L): L = leftModule.scalar.times(x, y)
    }

    implicit def ringAsLeftModule[R](implicit ring: Ring[R]): LeftModuleSelf[R] = new LeftModuleSelf[R] {
      override def scalar: Ring[R] = ring

      override def timesl(r: R, v: R): R = r * v

      override def negate(x: R): R = ring.negate(x)

      override def zero: R = ring.zero

      override def plus(x: R, y: R): R = ring.plus(x, y)
    }
  }

}
