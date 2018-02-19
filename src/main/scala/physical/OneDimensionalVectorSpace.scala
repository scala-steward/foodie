package physical

import spire.algebra.{Field, Module, Rng, VectorSpace}
import spire.syntax.field._

class OneDimensionalModule[R: Rng] extends Module[R, R] {
  override def scalar: Rng[R] = implicitly[Rng[R]]

  override def timesl(r: R, v: R): R = r * v

  override def negate(x: R): R = -x

  override def zero: R = scalar.zero

  override def plus(x: R, y: R): R = x + y
}

class OneDimensionalVectorSpace[F: Field] extends OneDimensionalModule[F] with VectorSpace[F, F]  {
  override def scalar: Field[F] = implicitly[Field[F]]
}