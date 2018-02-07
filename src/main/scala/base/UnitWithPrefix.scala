package base

import spire.math.Numeric

import scalaz.@@

/**
  * Representation of a scientific unit with a prefix (e.g. milligram).
  *
  * @param unadjusted The base value without any interpretation.
  * @tparam U The numeric type of the actual unit.
  * @tparam P A prefix type used for the proper scaling and the interpretation of the base value in the unit.
  */
case class UnitWithPrefix[U: Numeric, P: Prefix](unadjusted: U) {

  private val prefix: Prefix[P] = Prefix[P]

  /**
    * The factor by which the unadjusted value is scaled.
    */
  val unitFactor: U = prefix.factor

  /**
    * The actual value denoted by the particular instance.
    */
  val adjusted: U @@ P = prefix.scale(unadjusted)

  /**
    * Convert the value to another context.
    * For instance, one can change from micro to milli.
    *
    * @tparam Q The new prefix context.
    * @return A new unit with the same base value, but wrapped in a new context.
    */
  def rescale[Q: Prefix]: UnitWithPrefix[U, Q] = UnitWithPrefix.to[U, P, Q](this)
}

object UnitWithPrefix {

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
    UnitWithPrefix[U, P2](unit.unadjusted)
  }
}