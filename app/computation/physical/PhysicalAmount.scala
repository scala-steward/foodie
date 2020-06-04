package physical

import base.math.ScalarMultiplication
import physical.Prefix.Syntax._
import spire.algebra._
import spire.math.Numeric
import spire.syntax.vectorSpace._
import ScalarMultiplication.Syntax._

import scalaz.{@@, Tag}

/**
  * Representation of a scientific unit with a prefix (e.g. milligram).
  *
  * @param relative The base value without any interpretation.
  * @tparam N The numeric type of the actual unit.
  * @tparam P A prefix type used for the proper scaling and the interpretation of the base value in the unit.
  */
case class PhysicalAmount[N: Numeric, P](relative: N @@ P, prefix: Prefix[P]) {

  /**
    * The factor by which the unadjusted value is scaled.
    */
  val unitFactor: N = prefix.factor

  /**
    * The actual value denoted by the particular instance.
    *
    * Invariant: The absolute value is independent of the prefix.
    */
  lazy val absolute: N = prefix.scale(Tag.unwrap(relative))

  /**
    * Convert the value to another context.
    * For instance, one can change from micro to milli.
    *
    * @tparam Q The new prefix context.
    * @return A new unit with the same base value, but wrapped in a new context.
    */
  def rescale[Q: Prefix]: PhysicalAmount[N, Q] = PhysicalAmount.to[N, P, Q](this)(Numeric[N], prefix, Prefix[Q])

  def normalise: PhysicalAmount[N, _] = {
    val nPrefix = Prefix.normalisedPrefix(absolute)
    if (nPrefix != prefix)
      rescale(nPrefix)
    else
      this
  }

  override val toString: String = {
    s"PhysicalAmount(relative = $relative, prefix = ${prefix.name})"
  }
}

object PhysicalAmount {

  def fromRelative[U: Numeric, P: Prefix](relative: U): PhysicalAmount[U, P] = {
    PhysicalAmount[U, P](Tag[U, P](relative), Prefix[P])
  }

  /**
    * Convert between two units with prefixes.
    *
    * @param unit The original unit with a certain prefix.
    * @tparam U  The unit type.
    * @tparam P1 The first (original) prefix type.
    * @tparam P2 The second (target) prefix type.
    * @return A unit with the same base value, but another prefix context.
    */
  def to[U: Numeric, P1: Prefix, P2: Prefix](unit: PhysicalAmount[U, P1]):
  PhysicalAmount[U, P2] = {
    val inner = Prefix[P2].unscale(unit.absolute)
    PhysicalAmount.fromRelative[U, P2](inner)
  }

  def fromAbsolute[N: Numeric, P: Prefix](absolute: N): PhysicalAmount[N, P] =
    fromRelative[N, Single](absolute)(Numeric[N], Single).rescale[P]

  object Implicits {

    private class PhysicalAmountSG[N: Numeric, P] extends AdditiveSemigroup[PhysicalAmount[N, P]] {
      override def plus(x: PhysicalAmount[N, P], y: PhysicalAmount[N, P]): PhysicalAmount[N, P] =
        PhysicalAmount.fromRelative[N, P](Tag.unwrap(x.relative) + Tag.unwrap(y.relative))(Numeric[N], x.prefix)
    }

    private class PhysicalAmountMonoid[N: Numeric, P: Prefix]
      extends PhysicalAmountSG[N, P] with AdditiveMonoid[PhysicalAmount[N, P]] {
      override def zero: PhysicalAmount[N, P] =
        PhysicalAmount.fromRelative[N, P](AdditiveMonoid[N].zero)(Numeric[N], Prefix[P])
    }

    private class PhysicalAmountAG[N: Numeric, P: Prefix]
      extends PhysicalAmountMonoid[N, P] with AdditiveGroup[PhysicalAmount[N, P]] {
      override def negate(x: PhysicalAmount[N, P]): PhysicalAmount[N, P] =
        PhysicalAmount.fromRelative[N, P](-Tag.unwrap(x.relative))(Numeric[N], x.prefix)
    }

    private class PhysicalAmountAAG[N: Numeric, P: Prefix]
      extends PhysicalAmountAG[N, P] with AdditiveAbGroup[PhysicalAmount[N, P]]

    private class PhysicalAmountModule[N: Numeric, P: Prefix, R: Rng](implicit mod: Module[N, R])
      extends PhysicalAmountAAG[N, P] with Module[PhysicalAmount[N, P], R] {
      override def scalar: Rng[R] = implicitly[Rng[R]]

      override def timesl(r: R, v: PhysicalAmount[N, P]): PhysicalAmount[N, P] = {
        PhysicalAmount.fromRelative(r *: Tag.unwrap(v.relative))(Numeric[N], v.prefix)
      }

    }

    private class PhysicalAmountVS[N: Numeric, P: Prefix, F: Field](implicit vs: VectorSpace[N, F])
      extends PhysicalAmountModule[N, P, F] with VectorSpace[PhysicalAmount[N, P], F] {
      override def scalar: Field[F] = implicitly[Field[F]]
    }

    private class PhysicalAmountSM[R, N: Numeric, P: Prefix](implicit sm: ScalarMultiplication[R, N])
      extends ScalarMultiplication[R, PhysicalAmount[N, P]] {
      override def scale(scalar: R, vector: PhysicalAmount[N, P]): PhysicalAmount[N, P] =
        PhysicalAmount.fromAbsolute(vector.absolute.scale(scalar))
    }

    implicit def additiveSemigroupPA[N: Numeric, P]: AdditiveSemigroup[PhysicalAmount[N, P]] =
      new PhysicalAmountSG[N, P]

    implicit def additiveMonoidPA[N: Numeric, P: Prefix]: AdditiveMonoid[PhysicalAmount[N, P]] =
      new PhysicalAmountMonoid[N, P]

    implicit def additiveGroupPA[N: Numeric, P: Prefix]: AdditiveGroup[PhysicalAmount[N, P]] =
      new PhysicalAmountAAG[N, P]

    implicit def additiveAbelianGroupPA[N: Numeric, P: Prefix]: AdditiveAbGroup[PhysicalAmount[N, P]] =
      new PhysicalAmountAAG[N, P]

    implicit def modulePA[N: Numeric, P: Prefix, R: Rng](implicit mod: Module[N, R]): Module[PhysicalAmount[N, P], R] =
      new PhysicalAmountModule[N, P, R]

    implicit def vectorSpacePA[N: Numeric, P: Prefix, F: Field](implicit vs: VectorSpace[N, F]):
    VectorSpace[PhysicalAmount[N, P], F] = new PhysicalAmountVS[N, P, F]

    implicit def scalarMultiplicationPA[R, N: Numeric, P: Prefix](implicit sm: ScalarMultiplication[R, N]):
    ScalarMultiplication[R, PhysicalAmount[N, P]] = new PhysicalAmountSM[R, N, P]
  }

}