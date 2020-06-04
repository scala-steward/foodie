package computation.base

import algebra.ring.AdditiveMonoid
import spire.algebra._
import spire.syntax.vectorSpace._
import computation.base.math.LeftModuleUtil.Implicits._

case class Functional[N, A](f: A => N) extends (A => N) {
  override def apply(v1: A): N = f(v1)
}

object Functional {

  def fromAssociations[A, R: AdditiveMonoid](associations: Iterable[(A, R)]): Functional[R, A] = {
    val summed = associations.groupBy(_._1).view.mapValues(as => AdditiveMonoid[R].sum(as.map(_._2))).toMap
    Functional(summed.getOrElse(_, AdditiveMonoid[R].zero))
  }

  object Implicits {

    implicit def functionalLeftModule[F, A](implicit leftModule: LeftModule[F, F]): LeftModule[Functional[F, A], F] = new LeftModule[Functional[F, A], F] {
      override implicit def scalar: Ring[F] = Ring[F]

      override def timesl(r: F, v: Functional[F, A]): Functional[F, A] = Functional(a => r * v(a))

      override def negate(x: Functional[F, A]): Functional[F, A] = Functional(a => -x(a))

      override def zero: Functional[F, A] = Functional(_ => scalar.zero)

      override def plus(x: Functional[F, A], y: Functional[F, A]): Functional[F, A] = Functional(a => x(a) + y(a))
    }

  }

}