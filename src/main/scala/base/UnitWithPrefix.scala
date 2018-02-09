package base

import spire.math.Numeric

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
}