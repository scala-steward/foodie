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

    implicit def functionalLeftModule[V, L, A](implicit leftModule: LeftModule[V, L]): LeftModule[Functional[V, A], L] = new LeftModule[Functional[V, A], L] {
      override def scalar: Ring[L] = leftModule.scalar

      override def timesl(r: L, v: Functional[V, A]): Functional[V, A] = Functional(a => r *: v(a))

      override def negate(x: Functional[V, A]): Functional[V, A] = Functional(a => -x(a))

      override def zero: Functional[V, A] = Functional(_ => leftModule.zero)

      override def plus(x: Functional[V, A], y: Functional[V, A]): Functional[V, A] = Functional(a => x(a) + y(a))
    }

  }

}