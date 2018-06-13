package base.math

import spire.implicits._
import spire.math.Numeric

import scala.language.implicitConversions

trait ScalarMultiplication[R, V] {
  def scale(scalar: R, vector: V): V
}

object ScalarMultiplication {

  class ScalarMultiplicationOps[V](val vector: V) extends AnyVal {
    def scale[R](scalar: R)(implicit sm: ScalarMultiplication[R, V]): V = sm.scale(scalar, vector)
  }

  private class IdentitySM[N: Numeric] extends ScalarMultiplication[N, N] {
    override def scale(scalar: N, vector: N): N = scalar * vector
  }

  trait Syntax {
    implicit def toScalarMultiplicationOps[V](vector: V): ScalarMultiplicationOps[V] =
      new ScalarMultiplicationOps(vector)

    implicit def scalarMultiplicationI[N: Numeric]: ScalarMultiplication[N, N] = new IdentitySM[N]
  }

  object Syntax extends Syntax

}
