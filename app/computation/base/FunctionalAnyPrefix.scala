package base

import algebra.ring.{AdditiveGroup, AdditiveSemigroup}
import physical.NamedUnitAnyPrefix.Implicits._
import physical.Prefix.Syntax._
import physical._
import spire.algebra.{AdditiveAbGroup, AdditiveMonoid, Module, Rng}
import spire.math.Numeric

object FunctionalAnyPrefix {

  object Implicits {

    class FapASG[A, N: Numeric, U: PUnit] extends AdditiveSemigroup[Functional[NamedUnit[N, _, U], A]] {

      private def asg[P]: AdditiveSemigroup[NamedUnit[N, _, U]] =
        NamedUnitAnyPrefix.Implicits.additiveSemigroupNUAP[N, P, U](Numeric[N], PUnit[U])

      override def plus(x: Functional[NamedUnit[N, _, U], A],
                        y: Functional[NamedUnit[N, _, U], A]): Functional[NamedUnit[N, _, U], A] = {

        def catchType[P](a: NamedUnit[N, P, U], b: NamedUnit[N, _, U]): NamedUnit[N, _, U] = {
          asg[P].plus(a, b).normalised
        }

        Functional(a => catchType(x(a), y(a)))
      }
    }

    class FapAM[A, N: Numeric, U: PUnit]
      extends FapASG[A, N, U] with AdditiveMonoid[Functional[NamedUnit[N, _, U], A]] {

      private val am: AdditiveMonoid[NamedUnit[N, Single, U]] = NamedUnit.Implicits.additiveMonoidNU[N, Single, U]

      override def zero: Functional[NamedUnit[N, _, U], A] =
        Functional(_ => am.zero)
    }

    class FapAG[A, N: Numeric, U: PUnit]
      extends FapAM[A, N, U] with AdditiveGroup[Functional[NamedUnit[N, _, U], A]] {

      private def ag[P] = NamedUnitAnyPrefix.Implicits.additiveGroupNUAP[N, P, U]

      override def negate(x: Functional[NamedUnit[N, _, U], A]): Functional[NamedUnit[N, _, U], A] = {
        def catchType[P](n: NamedUnit[N, P, U]): NamedUnit[N, _, U] = ag[P].negate(n)

        Functional(a => catchType(x(a)))
      }
    }

    class FapAAG[A, N: Numeric, U: PUnit]
      extends FapAG[A, N, U] with AdditiveAbGroup[Functional[NamedUnit[N, _, U], A]]

    class FapM[A, N: Numeric, U: PUnit, R: Rng](implicit val modNR: Module[N, R])
      extends FapAAG[A, N, U] with Module[Functional[NamedUnit[N, _, U], A], R] {
      override val scalar: Rng[R] = Rng[R]

      private def mod[P] = NamedUnitAnyPrefix.Implicits.moduleNUAP[N, P, R, U]

      override def timesl(r: R, v: Functional[NamedUnit[N, _, U], A]): Functional[NamedUnit[N, _, U], A] = {
        def catchType[P](nu: NamedUnit[N, P, U]): NamedUnit[N, _, U] = {
          mod.timesl(r, nu)
        }

        Functional(a => catchType(v(a)))
      }
    }

    implicit def fapASG[A, N: Numeric, U: PUnit]: AdditiveSemigroup[Functional[NamedUnit[N, _, U], A]] =
      new FapASG[A, N, U]

    implicit def fapAM[A, N: Numeric, U: PUnit]: AdditiveMonoid[Functional[NamedUnit[N, _, U], A]] = new FapAM[A, N, U]

    implicit def fapAG[A, N: Numeric, U: PUnit]: AdditiveGroup[Functional[NamedUnit[N, _, U], A]] = new FapAG[A, N, U]

    implicit def fapAAG[A, N: Numeric, U: PUnit]: AdditiveAbGroup[Functional[NamedUnit[N, _, U], A]] =
      new FapAAG[A, N, U]

    implicit def fapM[A, N: Numeric, U: PUnit, R: Rng](implicit modNR: Module[N, R]):
    Module[Functional[NamedUnit[N, _, U], A], R] = new FapM[A, N, U, R]
  }

}
