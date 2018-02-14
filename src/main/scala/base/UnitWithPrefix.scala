package base

import algebra.ring.{AdditiveMonoid, AdditiveSemigroup}
import base.Prefix.Syntax.Single
import spire.algebra._
import spire.math.Numeric
import spire.syntax.vectorSpace._

import scalaz.{@@, Tag}

/**
  * Representation of a scientific unit with a prefix (e.g. milligram).
  *
  * @param relative The base value without any interpretation.
  * @tparam U The numeric type of the actual unit.
  * @tparam P A prefix type used for the proper scaling and the interpretation of the base value in the unit.
  */
case class UnitWithPrefix[U: Numeric, P: Prefix](relative: U @@ P) {

  private val prefix: Prefix[P] = Prefix[P]

  /**
    * The factor by which the unadjusted value is scaled.
    */
  val unitFactor: U = prefix.factor

  /**
    * The actual value denoted by the particular instance.
    *
    * Invariant: The absolute value is independent of the prefix.
    */
  val absolute: U = prefix.scale(Tag.unwrap(relative))

  /**
    * Convert the value to another context.
    * For instance, one can change from micro to milli.
    *
    * @tparam Q The new prefix context.
    * @return A new unit with the same base value, but wrapped in a new context.
    */
  def rescale[Q: Prefix]: UnitWithPrefix[U, Q] = UnitWithPrefix.to[U, P, Q](this)

  def normalise: UnitWithPrefix[U, _] = {
    val nPrefix = Prefix.normalisedPrefix(absolute)
    if (nPrefix != prefix)
      rescale(nPrefix)
    else
      this
  }

  override val toString: String = {
    s"UnitWithPrefix(relative = $relative, prefix = ${prefix.name})"
  }
}

object UnitWithPrefix {

  def fromRelative[U: Numeric, P: Prefix](relative: U): UnitWithPrefix[U, P] = UnitWithPrefix(Tag(relative))

  /**
    * Convert between two units with prefixes.
    *
    * @param unit The original unit with a certain prefix.
    * @tparam U  The unit type.
    * @tparam P1 The first (original) prefix type.
    * @tparam P2 The second (target) prefix type.
    * @return A unit with the same base value, but another prefix context.
    */
  def to[U: Numeric, P1, P2: Prefix](unit: UnitWithPrefix[U, P1]): UnitWithPrefix[U, P2] = {
    UnitWithPrefix[U, P2](Prefix[P2].unscale(unit.absolute))
  }

  object Implicits {

    private class UnitWithPrefixSG[V: Numeric] extends AdditiveSemigroup[UnitWithPrefix[V, _]] {
      override def plus(x: UnitWithPrefix[V, _], y: UnitWithPrefix[V, _]): UnitWithPrefix[V, _] =
        UnitWithPrefix.fromRelative[V, Single](x.absolute + y.absolute).normalise
    }

    private class UnitWithPrefixMonoid[V: Numeric]
      extends UnitWithPrefixSG[V] with AdditiveMonoid[UnitWithPrefix[V, _]] {
      override def zero: UnitWithPrefix[V, _] =
        UnitWithPrefix.fromRelative[V, Single](AdditiveMonoid[V].zero)
    }

    private class UnitWithPrefixAG[V: Numeric]
      extends UnitWithPrefixMonoid[V] with AdditiveGroup[UnitWithPrefix[V, _]] {
      override def negate(x: UnitWithPrefix[V, _]): UnitWithPrefix[V, _] =
        UnitWithPrefix.fromRelative(-Tag.unwrap(x.relative))
    }

    private class UnitWithPrefixAAG[V: Numeric]
      extends UnitWithPrefixAG[V] with AdditiveAbGroup[UnitWithPrefix[V, _]]

    private class UnitWithPrefixModule[V: Numeric, R: Rng](implicit mod: Module[V, R])
      extends UnitWithPrefixAAG[V] with Module[UnitWithPrefix[V, _], R] {
      override def scalar: Rng[R] = implicitly[Rng[R]]

      override def timesl(r: R, v: UnitWithPrefix[V, _]): UnitWithPrefix[V, _] = {
        UnitWithPrefix.fromRelative(r *: v.absolute).normalise
      }

    }

    private class UnitWithPrefixVS[V: Numeric, F: Field](implicit vs: VectorSpace[V, F])
      extends UnitWithPrefixModule[V, F] with VectorSpace[UnitWithPrefix[V, _], F] {
      override def scalar: Field[F] = implicitly[Field[F]]
    }

    implicit def additiveSemigroup[V: Numeric]: AdditiveSemigroup[UnitWithPrefix[V, _]] =
      new UnitWithPrefixSG[V]

    implicit def additiveMonoid[V: Numeric]: AdditiveMonoid[UnitWithPrefix[V, _]] = new UnitWithPrefixMonoid[V]

    implicit def additiveGroup[V: Numeric]: AdditiveGroup[UnitWithPrefix[V, _]] = new UnitWithPrefixAAG[V]

    implicit def additiveAbelianGroup[V: Numeric]: AdditiveAbGroup[UnitWithPrefix[V, _]] = new UnitWithPrefixAAG[V]

    implicit def module[V: Numeric, R: Rng](implicit mod: Module[V, R]): Module[UnitWithPrefix[V, _], R] =
      new UnitWithPrefixModule[V, R]

    implicit def vectorSpace[V: Numeric, F: Field](implicit vs: VectorSpace[V, F]):
    VectorSpace[UnitWithPrefix[V, _], F] = new UnitWithPrefixVS[V, F]
  }

}