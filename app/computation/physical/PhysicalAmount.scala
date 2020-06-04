package computation.physical

import spire.algebra.{Field, VectorSpace}
import spire.syntax.vectorSpace._

case class PhysicalAmount[N](value: N)

object PhysicalAmount {

  object Implicits {

    implicit def physicalAmountVectorSpace[F: Field]: VectorSpace[PhysicalAmount[F], F] = new VectorSpace[PhysicalAmount[F], F] {
      override def scalar: Field[F] = Field[F]

      override def timesl(r: F, v: PhysicalAmount[F]): PhysicalAmount[F] = v.copy(value = r * v.value)

      override def negate(x: PhysicalAmount[F]): PhysicalAmount[F] = x.copy(value = -x.value)

      override def zero: PhysicalAmount[F] = PhysicalAmount(Field[F].zero)

      override def plus(x: PhysicalAmount[F], y: PhysicalAmount[F]): PhysicalAmount[F] =
        PhysicalAmount(x.value + y.value)
    }

  }

}