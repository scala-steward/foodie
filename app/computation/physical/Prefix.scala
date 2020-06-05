package computation.physical

import computation.base.Floating
import spire.math.Numeric
import spire.syntax.numeric._

/**
  * A type denoting the scientific prefix of a certain unit (i.e. "milli").
  */
sealed trait Prefix[P] {

  type PrefixType = P
  // TODO: Adjust rescaling, since this is only relevant in the final display.
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
  def scale[A: Numeric](value: A): A = value * factor

  /**
    * Given a value in the prefix format (i.e. interpreted in this format),
    * convert the value back to its original size.
    *
    * @param value The scaled value.
    * @tparam A The type of the scaled value.
    * @return The original value stripped of any tags.
    */
  def unscale[A: Numeric](value: A): A = value / factor

  /**
    * @return The name of the prefix.
    */
  def name: String

  /**
    * @return The abbreviated name of the prefix.
    */
  def abbreviation: String
}

object Prefix {

  def apply[P: Prefix]: Prefix[P] = implicitly[Prefix[P]]

  def fromAbbreviation(name: String): Option[Prefix[_]] = Syntax.All.find(_.abbreviation == name)

  def fromName(name: String): Option[Prefix[_]] = Syntax.All.find(_.name == name)

  object Syntax extends Syntax

  sealed trait Syntax {

    case object Nano extends Nano

    case object Micro extends Micro

    case object Milli extends Milli

    case object Single extends Single

    case object Kilo extends Kilo

    implicit val nanoPrefix: Prefix[Nano] = Nano
    implicit val microPrefix: Prefix[Micro] = Micro
    implicit val milliPrefix: Prefix[Milli] = Milli
    implicit val singlePrefix: Prefix[Single] = Single
    implicit val kiloPrefix: Prefix[Kilo] = Kilo

    val All: List[Prefix[_]] = List(Nano, Micro, Milli, Single, Kilo)

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
  override val name: String = "nano"
  override val abbreviation: String = "n"
}

sealed trait Micro extends PrefixFrom[Micro] {
  override protected final val floatingFactor: Floating = 1e-6
  override val name: String = "micro"
  override val abbreviation: String = "µ"
}

sealed trait Milli extends PrefixFrom[Milli] {
  override protected final val floatingFactor: Floating = 1e-3
  override val name: String = "milli"
  override val abbreviation: String = "m"
}

sealed trait Single extends PrefixFrom[Single] {
  override protected final val floatingFactor: Floating = 1d
  override val name: String = ""
  override val abbreviation: String = ""
}

sealed trait Kilo extends PrefixFrom[Kilo] {
  override protected final val floatingFactor: Floating = 1e3
  override val name: String = "kilo"
  override val abbreviation: String = "k"
}
