package physical

import physical.PhysicalAmount.Implicits._
import spire.algebra._
import spire.implicits._
import spire.math.Numeric

case class NamedUnit[N: Numeric, P, U: PUnit](amount: PhysicalAmount[N, P]) {

  private val unit: PUnit[U] = PUnit[U]
  val prefix: Prefix[P] = amount.prefix

  override val toString: String = NamedUnit.mkString(prefix.name, unit.name)(amount)

  val abbreviated: String = NamedUnit.mkString(prefix.abbreviation, unit.abbreviation)(amount)

  lazy val normalised: NamedUnit[N, _, U] = {
    val total = amount.normalise
    NamedUnit(total)
  }
}

object NamedUnit {
  private def mkString(prefixName: String, unitName: String)
                      (amount: PhysicalAmount[_, _]): String = {
    s"${amount.relative} $prefixName$unitName"
  }

  object Implicits {

    private class NamedUnitSG[N: Numeric, P, U: PUnit]
      extends AdditiveSemigroup[NamedUnit[N, P, U]] {
      override def plus(x: NamedUnit[N, P, U], y: NamedUnit[N, P, U]): NamedUnit[N, P, U] =
        NamedUnit(x.amount + y.amount)
    }

    private class NamedUnitMonoid[N: Numeric, P: Prefix, U: PUnit]
      extends NamedUnitSG[N, P, U] with AdditiveMonoid[NamedUnit[N, P, U]] {
      override def zero: NamedUnit[N, P, U] = NamedUnit(AdditiveMonoid[PhysicalAmount[N, P]].zero)
    }

    private class NamedUnitAG[N: Numeric, P: Prefix, U: PUnit]
      extends NamedUnitMonoid[N, P, U] with AdditiveGroup[NamedUnit[N, P, U]] {
      override def negate(x: NamedUnit[N, P, U]): NamedUnit[N, P, U] = NamedUnit(-x.amount)
    }

    private class NamedUnitAAG[N: Numeric, P: Prefix, U: PUnit]
      extends NamedUnitAG[N, P, U] with AdditiveAbGroup[NamedUnit[N, P, U]]

    private class NamedUnitModule[N: Numeric, P: Prefix, R: Rng, U: PUnit](implicit mod: Module[N, R])
      extends NamedUnitAAG[N, P, U] with Module[NamedUnit[N, P, U], R] {
      override def scalar: Rng[R] = implicitly[Rng[R]]

      override def timesl(r: R, v: NamedUnit[N, P, U]): NamedUnit[N, P, U] = {
        NamedUnit(r *: v.amount)
      }

    }

    private class NamedUnitVS[N: Numeric, P: Prefix, F: Field, U: PUnit](implicit vs: VectorSpace[N, F])
      extends NamedUnitModule[N, P, F, U] with VectorSpace[NamedUnit[N, P, U], F] {
      override def scalar: Field[F] = implicitly[Field[F]]
    }

    implicit def additiveSemigroupNU[N: Numeric, P, U: PUnit]: AdditiveSemigroup[NamedUnit[N, P, U]] =
      new NamedUnitSG[N, P, U]

    implicit def additiveMonoidNU[N: Numeric, P: Prefix, U: PUnit]: AdditiveMonoid[NamedUnit[N, P, U]] =
      new NamedUnitMonoid[N, P, U]

    implicit def additiveGroupNU[N: Numeric, P: Prefix, U: PUnit]: AdditiveGroup[NamedUnit[N, P, U]] =
      new NamedUnitAAG[N, P, U]

    implicit def additiveAbelianGroupNU[N: Numeric, P: Prefix, U: PUnit]: AdditiveAbGroup[NamedUnit[N, P, U]] =
      new NamedUnitAAG[N, P, U]

    implicit def moduleNU[N: Numeric, P: Prefix, R: Rng, U: PUnit]
    (implicit mod: Module[N, R]): Module[NamedUnit[N, P, U], R] = new NamedUnitModule[N, P, R, U]

    implicit def vectorSpaceNU[N: Numeric, P: Prefix, F: Field, U: PUnit](implicit vs: VectorSpace[N, F]):
    VectorSpace[NamedUnit[N, P, U], F] = new NamedUnitVS[N, P, F, U]
  }

}