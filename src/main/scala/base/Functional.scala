package base

import algebra.ring.{AdditiveMonoid, AdditiveSemigroup}
import spire.algebra._
import spire.implicits._

case class Functional[N, A](f: A => N) extends (A => N) {
  override def apply(v1: A): N = f(v1)
}

object Functional {

  object Implicits {

    private class FSG[N: AdditiveSemigroup, A] extends AdditiveSemigroup[Functional[N, A]] {
      override def plus(x: Functional[N, A], y: Functional[N, A]): Functional[N, A] =
        Functional(a => x(a) + y(a))
    }

    private class FM[N: AdditiveMonoid, A] extends FSG[N, A] with AdditiveMonoid[Functional[N, A]] {
      override def zero: Functional[N, A] = Functional(_ => AdditiveMonoid[N].zero)
    }

    private class FAG[N: AdditiveGroup, A] extends FM[N, A] with AdditiveGroup[Functional[N, A]] {
      override def negate(x: Functional[N, A]): Functional[N, A] = Functional(a => -x(a))
    }

    private class FAAG[N: AdditiveAbGroup, A] extends FAG[N, A] with AdditiveAbGroup[Functional[N, A]]

    private class FMod[N, A, R: Rng](implicit val mod: Module[N, R])
      extends FAG[N, A] with Module[Functional[N, A], R] {
      override def scalar: Rng[R] = implicitly[Rng[R]]

      override def timesl(r: R, v: Functional[N, A]): Functional[N, A] = Functional(a => r *: v(a))
    }

    private class FVS[N: Field, A] extends FMod[N, A, N] with VectorSpace[Functional[N, A], N] {
      override def scalar: Field[N] = implicitly[Field[N]]
    }

    implicit def additiveSemigroup[N: AdditiveSemigroup, A]: AdditiveSemigroup[Functional[N, A]] = new FSG[N, A]

    implicit def additiveMonoid[N: AdditiveMonoid, A]: AdditiveMonoid[Functional[N, A]] = new FM[N, A]

    implicit def additiveGroup[N: AdditiveGroup, A]: AdditiveGroup[Functional[N, A]] = new FAG[N, A]

    implicit def additiveAbelianGroup[N: AdditiveAbGroup, A]: AdditiveAbGroup[Functional[N, A]] = new FAAG[N, A]

    implicit def module[N, A, R: Rng](implicit mod: Module[N, R]): Module[Functional[N, A], R] = new FMod[N, A, R]

    implicit def vectorSpace[N: Field, A]: VectorSpace[Functional[N, A], N] = new FVS[N, A]

  }

}