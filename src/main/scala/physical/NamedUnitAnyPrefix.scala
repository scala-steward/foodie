package physical

import spire.algebra._
import spire.math.Numeric
import spire.implicits._
import PhysicalAmount.Implicits._
import PUnit.Syntax._
import algebra.ring.AdditiveMonoid
import NamedUnit.Implicits._

import scala.reflect.ClassTag

object NamedUnitAnyPrefix {

  object Implicits {

    private def modHom[N: Numeric, U: PUnit]: Module[NamedUnit[N, _ <: Prefix, U], N] = modHet[N, N, U]

    private def modHet[N: Numeric, R: Rng, U: PUnit](implicit mod: Module[N, R])
    : Module[NamedUnit[N, _ <: Prefix, U], R] = new Module[NamedUnit[N, _ <: Prefix, U], R] {
      override val scalar: Rng[R] = Rng[R]

      override def timesl(r: R, v: NamedUnit[N, _ <: Prefix, U]): NamedUnit[N, _ <: Prefix, U] = {
        def catchType[P <: Prefix: ClassTag](nu: NamedUnit[N, P, U]): NamedUnit[N, P, U] = r *: nu
        catchType(v)
      }

      override def negate(x: NamedUnit[N, _ <: Prefix, U]): NamedUnit[N, _ <: Prefix, U] = {
        def catchType[P <: Prefix: ClassTag](nu: NamedUnit[N, P, U]): NamedUnit[N, _ <: Prefix, U] = -nu
        catchType(x)
      }

      override def zero: NamedUnit[N, _ <: Prefix, U] = AdditiveMonoid[NamedUnit[N, Single, U]].zero

      override def plus(x: NamedUnit[N, _ <: Prefix, U],
                        y: NamedUnit[N, _ <: Prefix, U]): NamedUnit[N, _ <: Prefix, U] = {
        def catchType[P <: Prefix: ClassTag, _ <: Prefix](a: NamedUnit[N, P, U],
                                                          b: NamedUnit[N, _, U]): NamedUnit[N, P, U] = {
          a + NamedUnit[N, P, U](b.amount.rescale[P])
        }
        catchType(x, y)
      }
    }

    implicit def additiveSemigroupNUAP[N: Numeric, _ <: Prefix : ClassTag, U: PUnit]:
    AdditiveSemigroup[NamedUnit[N, _ <: Prefix, U]] = modHom


    implicit def additiveMonoidNUAP[N: Numeric, _ <: Prefix : ClassTag, U: PUnit]:
    AdditiveMonoid[NamedUnit[N, _ <: Prefix, U]] = modHom

    implicit def additiveGroupNUAP[N: Numeric, _ <: Prefix : ClassTag, U: PUnit]:
    AdditiveGroup[NamedUnit[N, _ <: Prefix, U]] = modHom

    implicit def additiveAbelianGroupNUAP[N: Numeric, _ <: Prefix : ClassTag, U: PUnit]
    : AdditiveAbGroup[NamedUnit[N, _ <: Prefix, U]] = modHom

    implicit def moduleNUAP[N: Numeric, _ <: Prefix : ClassTag, R: Rng, U: PUnit]
    (implicit mod: Module[N, R]): Module[NamedUnit[N, _ <: Prefix, U], R] = modHet

  }

}
