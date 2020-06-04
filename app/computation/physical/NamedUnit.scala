package computation.physical

import computation.base.math.LeftModuleUtil.Implicits._
import computation.base.math.LeftModuleUtil.LeftModuleSelf
import computation.physical.PUnit.Syntax._
import computation.physical.PhysicalAmount.Implicits._
import spire.algebra._
import spire.syntax.vectorSpace._

case class NamedUnit[N, U: PUnit](amount: PhysicalAmount[N])

object NamedUnit {

  def gram[F](amount: PhysicalAmount[F]): NamedUnit[F, Gram] = NamedUnit[F, Gram](amount)

  def litre[F](amount: PhysicalAmount[F]): NamedUnit[F, Litre] = NamedUnit[F, Litre](amount)

  object Implicits {

    implicit def namedUnitLeftModule[L: LeftModuleSelf, U: PUnit]: LeftModule[NamedUnit[L, U], L] = new LeftModule[NamedUnit[L, U], L] {
      override def scalar: Ring[L] = Ring[L]

      override def timesl(r: L, v: NamedUnit[L, U]): NamedUnit[L, U] = v.copy(amount = r *: v.amount)

      override def negate(x: NamedUnit[L, U]): NamedUnit[L, U] = x.copy(amount = -x.amount)

      override def zero: NamedUnit[L, U] = NamedUnit(AdditiveMonoid[PhysicalAmount[L]].zero)

      override def plus(x: NamedUnit[L, U], y: NamedUnit[L, U]): NamedUnit[L, U] =
        NamedUnit(x.amount + y.amount)
    }
  }

}