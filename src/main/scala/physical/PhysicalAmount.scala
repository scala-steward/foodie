package physical

import spire.algebra._
import spire.math.Numeric
import spire.syntax.vectorSpace._

import scala.reflect.ClassTag
import scalaz.{@@, Tag}

/**
  * Representation of a scientific unit with a prefix (e.g. milligram).
  *
  * @param relative The base value without any interpretation.
  * @tparam U The numeric type of the actual unit.
  * @tparam P A prefix type used for the proper scaling and the interpretation of the base value in the unit.
  */
case class PhysicalAmount[U: Numeric, P <: Prefix: ClassTag](relative: U @@ P) {

  val prefix: Prefix = Prefix[P]

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
  def rescale[Q <: Prefix: ClassTag]: PhysicalAmount[U, Q] = PhysicalAmount.to[U, P, Q](this)

  def normaliseWithPrefix: (PhysicalAmount[U, _ <: Prefix], Prefix) = {
    val nPrefix = Prefix.normalisedPrefix(absolute)
    if (nPrefix != prefix)
      (rescale[nPrefix.PrefixType](nPrefix.classTag), nPrefix)
    else
      (this, prefix)
  }

  def normalise: PhysicalAmount[U, _ <: Prefix] = normaliseWithPrefix._1

  override val toString: String = {
    s"PhysicalAmount(relative = $relative, prefix = ${prefix.name})"
  }
}

object PhysicalAmount {

  def fromRelative[U: Numeric, P <: Prefix: ClassTag](relative: U): PhysicalAmount[U, P] =
    PhysicalAmount(Tag[U, P](relative))

  /**
    * Convert between two units with prefixes.
    *
    * @param unit The original unit with a certain prefix.
    * @tparam U  The unit type.
    * @tparam P1 The first (original) prefix type.
    * @tparam P2 The second (target) prefix type.
    * @return A unit with the same base value, but another prefix context.
    */
  def to[U: Numeric, P1 <: Prefix: ClassTag, P2 <: Prefix: ClassTag](unit: PhysicalAmount[U, P1]):
  PhysicalAmount[U, P2] = {
    val inner = Prefix[P2].unscale(unit.absolute)
    PhysicalAmount.fromAbsolute[U, P2](inner)
  }

  def fromAbsolute[N: Numeric, P <: Prefix: ClassTag](absolute: N): PhysicalAmount[N, P] =
    fromRelative[N, Single](absolute).rescale[P]

  object Implicits {

    private class PhysicalAmountSG[V: Numeric, P <: Prefix: ClassTag] extends AdditiveSemigroup[PhysicalAmount[V, P]] {
      override def plus(x: PhysicalAmount[V, P], y: PhysicalAmount[V, P]): PhysicalAmount[V, P] =
        PhysicalAmount.fromRelative[V, P](Tag.unwrap(x.relative) + Tag.unwrap(y.relative))
    }

    private class PhysicalAmountMonoid[V: Numeric, P <: Prefix: ClassTag]
      extends PhysicalAmountSG[V, P] with AdditiveMonoid[PhysicalAmount[V, P]] {
      override def zero: PhysicalAmount[V, P] =
        PhysicalAmount.fromRelative[V, P](AdditiveMonoid[V].zero)
    }

    private class PhysicalAmountAG[V: Numeric, P <: Prefix: ClassTag]
      extends PhysicalAmountMonoid[V, P] with AdditiveGroup[PhysicalAmount[V, P]] {
      override def negate(x: PhysicalAmount[V, P]): PhysicalAmount[V, P] =
        PhysicalAmount.fromRelative(-Tag.unwrap(x.relative))
    }

    private class PhysicalAmountAAG[V: Numeric, P <: Prefix: ClassTag]
      extends PhysicalAmountAG[V, P] with AdditiveAbGroup[PhysicalAmount[V, P]]

    private class PhysicalAmountModule[V: Numeric, P <: Prefix: ClassTag, R: Rng](implicit mod: Module[V, R])
      extends PhysicalAmountAAG[V, P] with Module[PhysicalAmount[V, P], R] {
      override def scalar: Rng[R] = implicitly[Rng[R]]

      override def timesl(r: R, v: PhysicalAmount[V, P]): PhysicalAmount[V, P] = {
        PhysicalAmount.fromRelative(r *: Tag.unwrap(v.relative))
      }

    }

    private class PhysicalAmountVS[V: Numeric, P <: Prefix: ClassTag, F: Field](implicit vs: VectorSpace[V, F])
      extends PhysicalAmountModule[V, P, F] with VectorSpace[PhysicalAmount[V, P], F] {
      override def scalar: Field[F] = implicitly[Field[F]]
    }

    implicit def additiveSemigroupPA[V: Numeric, P <: Prefix: ClassTag]: AdditiveSemigroup[PhysicalAmount[V, P]] =
      new PhysicalAmountSG[V, P]

    implicit def additiveMonoidPA[V: Numeric, P <: Prefix: ClassTag]: AdditiveMonoid[PhysicalAmount[V, P]] =
      new PhysicalAmountMonoid[V, P]

    implicit def additiveGroupPA[V: Numeric, P <: Prefix: ClassTag]: AdditiveGroup[PhysicalAmount[V, P]] =
      new PhysicalAmountAAG[V, P]

    implicit def additiveAbelianGroupPA[V: Numeric, P <: Prefix: ClassTag]: AdditiveAbGroup[PhysicalAmount[V, P]] =
      new PhysicalAmountAAG[V, P]

    implicit def modulePA[V: Numeric, P <: Prefix: ClassTag, R: Rng]
    (implicit mod: Module[V, R]): Module[PhysicalAmount[V, P], R] =
      new PhysicalAmountModule[V, P, R]

    implicit def vectorSpacePA[V: Numeric, P <: Prefix: ClassTag, F: Field](implicit vs: VectorSpace[V, F]):
    VectorSpace[PhysicalAmount[V, P], F] = new PhysicalAmountVS[V, P, F]
  }

}