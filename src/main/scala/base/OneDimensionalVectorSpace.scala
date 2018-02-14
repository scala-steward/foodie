package base

import spire.algebra.{Field, VectorSpace}
import spire.syntax.field._

class OneDimensionalVectorSpace[F: Field] extends VectorSpace[F, F] {
  override def scalar: Field[F] = implicitly[Field[F]]

  override def timesl(r: F, v: F): F = r * v

  override def negate(x: F): F = -x

  override def zero: F = scalar.zero

  override def plus(x: F, y: F): F = x + y
}