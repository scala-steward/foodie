package physical

import algebra.ring.AdditiveMonoid
import physical.PhysicalAmount.Implicits._
import spire.algebra._
import spire.implicits._
import spire.math.Numeric
import Prefix.Syntax._
import base.math.ScalarMultiplication

object NamedUnitAnyPrefix {

  object Implicits {

    //todo Restructure with classes as everywhere else.
    private def modHom[N: Numeric, U: PUnit]: Module[NamedUnit[N, _, U], N] = modHet[N, N, U]

    private def modHet[N: Numeric, R: Rng, U: PUnit](implicit mod: Module[N, R])
    : Module[NamedUnit[N, _, U], R] = new Module[NamedUnit[N, _, U], R] {
      override val scalar: Rng[R] = Rng[R]

      private implicit def module[P](implicit prefix: Prefix[P]): Module[NamedUnit[N, P, U], R] =
        NamedUnit.Implicits.moduleNU[N, P, R, U](Numeric[N], prefix, Rng[R], PUnit[U], mod)

      override def timesl(r: R, v: NamedUnit[N, _, U]): NamedUnit[N, _, U] = {
        def catchType[P](nu: NamedUnit[N, P, U]): NamedUnit[N, P, U] = {
          implicit val m: Module[NamedUnit[N, P, U], R] = module(nu.prefix)
          r *: nu
        }
        catchType(v)
      }

      override def negate(x: NamedUnit[N, _, U]): NamedUnit[N, _, U] = {
        def catchType[P](nu: NamedUnit[N, P, U]): NamedUnit[N, _, U] = {
          implicit val m: Module[NamedUnit[N, P, U], R] = module(nu.prefix)
          -nu
        }
        catchType(x)
      }

      override def zero: NamedUnit[N, _, U] = {
        implicit val m: Module[NamedUnit[N, Single, U], R] = module(Single)
        AdditiveMonoid[NamedUnit[N, Single, U]].zero
      }

      override def plus(x: NamedUnit[N, _, U],
                        y: NamedUnit[N, _, U]): NamedUnit[N, _, U] = {
        def catchType[P](a: NamedUnit[N, P, U], b: NamedUnit[N, _, U]): NamedUnit[N, P, U] = {
          implicit val m: Module[NamedUnit[N, P, U], R] = module(a.prefix)
          a + NamedUnit[N, P, U](b.amount.rescale[P](a.prefix))
        }
        catchType(x, y)
      }
    }

    implicit def additiveSemigroupNUAP[N: Numeric, _, U: PUnit]: AdditiveSemigroup[NamedUnit[N, _, U]] = modHom


    implicit def additiveMonoidNUAP[N: Numeric, _, U: PUnit]: AdditiveMonoid[NamedUnit[N, _, U]] = modHom

    implicit def additiveGroupNUAP[N: Numeric, _, U: PUnit]: AdditiveGroup[NamedUnit[N, _, U]] = modHom

    implicit def additiveAbelianGroupNUAP[N: Numeric, _, U: PUnit]: AdditiveAbGroup[NamedUnit[N, _, U]] = modHom

    implicit def moduleNUAP[N: Numeric, _, R: Rng, U: PUnit]
    (implicit mod: Module[N, R]): Module[NamedUnit[N, _, U], R] = modHet

  }

}
