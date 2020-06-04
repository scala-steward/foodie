package computation.base

import algebra.ring.AdditiveMonoid
import spire.algebra._
import spire.syntax.vectorSpace._

case class Functional[N, A](f: A => N) extends (A => N) {
  override def apply(v1: A): N = f(v1)
}

object Functional {

  def fromAssociations[A, R: AdditiveMonoid](associations: Iterable[(A, R)]): Functional[R, A] = {
    val summed = associations.groupBy(_._1).view.mapValues(as => AdditiveMonoid[R].sum(as.map(_._2))).toMap
    Functional(summed.getOrElse(_, AdditiveMonoid[R].zero))
  }

  object Implicits {

    implicit def vectorSpaceF[F: Field, A]: VectorSpace[Functional[F, A], F] = new VectorSpace[Functional[F, A], F] {
      override def scalar: Field[F] = Field[F]

      override def timesl(r: F, v: Functional[F, A]): Functional[F, A] = Functional(a => r * v(a))

      override def negate(x: Functional[F, A]): Functional[F, A] = Functional(a => -x(a))

      override def zero: Functional[F, A] = Functional(_ => scalar.zero)

      override def plus(x: Functional[F, A], y: Functional[F, A]): Functional[F, A] = Functional(a => x(a) + y(a))
    }

  }

}