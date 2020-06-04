package computation.physical

import computation.physical.PhysicalAmount.Implicits._
import physical.{Gram, Litre}
import spire.algebra._
import spire.syntax.vectorSpace._

case class NamedUnit[N, U](amount: PhysicalAmount[N])

object NamedUnit {

  def gram[F](amount: PhysicalAmount[F]): NamedUnit[F, Gram] = NamedUnit[F, Gram](amount)

  def litre[F](amount: PhysicalAmount[F]): NamedUnit[F, Litre] = NamedUnit[F, Litre](amount)

  object Implicits {

    implicit def namedUnitVectorSpace[F: Field, U]: VectorSpace[NamedUnit[F, U], F] = new VectorSpace[NamedUnit[F, U], F] {
      override def scalar: Field[F] = Field[F]

      override def timesl(r: F, v: NamedUnit[F, U]): NamedUnit[F, U] = v.copy(amount = r *: v.amount)

      override def negate(x: NamedUnit[F, U]): NamedUnit[F, U] = x.copy(amount = -x.amount)

      override def zero: NamedUnit[F, U] = NamedUnit(AdditiveMonoid[PhysicalAmount[F]].zero)

      override def plus(x: NamedUnit[F, U], y: NamedUnit[F, U]): NamedUnit[F, U] =
        NamedUnit(x.amount + y.amount)
    }
  }

}