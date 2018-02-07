package base

import spire.math.Numeric
import spire.syntax.numeric._

import scalaz.{@@, Tag}

/**
  * A type class denoting the scientific prefix of a certain unit (i.e. "milli").
  *
  * @tparam P The type that is used for tagging the adjusted value.
  */
sealed trait Prefix[P] {
  /**
    * @tparam A Any numeric instance.
    * @return The factor by which a value is multiplied when computed with this prefix.
    */
  def factor[A: Numeric]: A

  /**
    * Scale a given value by the underlying factor.
    *
    * @param value The value to be scaled.
    * @tparam A The type of the scaled value.
    * @return The rescaled value tagged with the type of the prefix to avoid erroneous use.
    */
  def scale[A: Numeric](value: A): @@[A, P] = Tag(value * factor)

  /**
    * Given a value in the prefix format (i.e. interpreted in this format),
    * convert the value back to its original size.
    *
    * @param value The scaled value.
    * @tparam A The type of the scaled value.
    * @return The original value stripped of any tags.
    */
  def unscale[A: Numeric](value: A @@ P): A = Tag.unwrap(value) / factor

}

object Prefix {

  def apply[P: Prefix]: Prefix[P] = implicitly[Prefix[P]]

  /**
    * Provide instances for the convenient use of the prefixes.
    * The objects extend the traits with the same name for the sake of convenience.
    * Usage example:
    *
    * {{{
    *
    * import Prefix.Syntax._
    *
    *   val unitWithPrefix = UnitWithPrefix[Floating, Micro](250d)
    *   println(unitWithPrefix.adjusted)
    *   val kilo = unitWithPrefix.rescale[Kilo]
    *   println(kilo.adjusted)
    *
    * }}}
    *
    */
  object Syntax extends Syntax

  sealed trait Syntax {

    implicit case object Nano extends Nano

    implicit case object Micro extends Micro

    implicit case object Milli extends Milli

    implicit case object Single extends Single

    implicit case object Kilo extends Kilo

  }

}

/**
  * Usually one creates prefix conversions by using a given floating value to rescale other values.
  * This trait abstracts this process and requires merely the floating value.
  */
sealed trait PrefixFrom[P] extends Prefix[P] {

  /**
    * @return A floating representation of the factor (which will be converted to the required numeric context).
    */
  protected def floatingFactor: Floating

  override final def factor[A: Numeric]: A = Numeric[A].fromBigDecimal(floatingFactor)
}

sealed trait Nano extends PrefixFrom[Nano] {
  override protected final val floatingFactor: Floating = 1e-9
}

sealed trait Micro extends PrefixFrom[Micro] {
  override protected final val floatingFactor: Floating = 1e-6
}

sealed trait Milli extends PrefixFrom[Milli] {
  override protected final val floatingFactor: Floating = 1e-3
}

sealed trait Single extends PrefixFrom[Single] {
  override protected final val floatingFactor: Floating = 1d
}

sealed trait Kilo extends PrefixFrom[Kilo] {
  override protected final val floatingFactor: Floating = 1e3
}
