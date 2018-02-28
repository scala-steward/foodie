package physical

import base._
import spire.math.{Interval, Numeric}
import spire.syntax.numeric._

import scala.reflect.ClassTag
import scalaz.Scalaz._
import scalaz.{@@, Tag, Zip}

/**
  * A type denoting the scientific prefix of a certain unit (i.e. "milli").
  */
sealed trait Prefix {

  type PrefixType <: Prefix

  implicit def classTag: ClassTag[PrefixType]

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

  import Syntax._

  private def prefixList: List[Prefix] = List(Nano, Micro, Milli, Single, Kilo)

  private def prefixOrder[A: Numeric]: Map[Interval[A], Prefix] = {
    val zipList = Zip[List]
    val num = Numeric[A]

    import zipList._

    val fs: List[(A, A) => Interval[A]] =
      List((_: A, upper: A) => Interval.below(upper)) ++
        prefixList.drop(2).map(_ => Interval.openUpper[A] _)++
        List((lower: A, _: A) => Interval.atOrAbove(lower) )

    val corners = prefixList.map(_.scale(num.fromBigDecimal(1d)))

    val bounds = zip(corners, corners.tail ++ List(num.fromBigDecimal(1d)))

    val responsibilities = zipWith(fs, bounds)((f, b) => f.tupled(b))
    zip(responsibilities, prefixList).toMap
  }

  def normalisedPrefix[A: Numeric](value: A): Prefix = {
    val order = prefixOrder[A]
    order.collectFirst {
      case (interval, prefix) if interval.contains(value) => prefix
    }.getOrElse(Single)
  }

  def apply[P <: Prefix: ClassTag]: Prefix = {
    prefixList.collectFirst { case x: P => x }.getOrElse(Single)
  }

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

    case object Nano extends Nano

    case object Micro extends Micro

    case object Milli extends Milli

    case object Single extends Single

    case object Kilo extends Kilo

  }

}

/**
  * Usually one creates prefix conversions by using a given floating value to rescale other values.
  * This trait abstracts this process and requires merely the floating value.
  */
sealed trait PrefixFrom extends Prefix {

  /**
    * @return A floating representation of the factor (which will be converted to the required numeric context).
    */
  protected def floatingFactor: Floating

  override final def factor[A: Numeric]: A = Numeric[A].fromBigDecimal(floatingFactor)
}

sealed trait Nano extends PrefixFrom {
  override type PrefixType = Nano
  override implicit val classTag: ClassTag[Nano] = implicitly[ClassTag[Nano]]
  override protected final val floatingFactor: Floating = 1e-9
  override val name: String = "nano"
  override val abbreviation: String = "n"
}

sealed trait Micro extends PrefixFrom {
  override type PrefixType = Micro
  override implicit def classTag: ClassTag[Micro] = implicitly[ClassTag[Micro]]
  override protected final val floatingFactor: Floating = 1e-6
  override val name: String = "micro"
  override val abbreviation: String = "µ"
}

sealed trait Milli extends PrefixFrom {
  override type PrefixType = Milli
  override implicit val classTag: ClassTag[Milli] = implicitly[ClassTag[Milli]]
  override protected final val floatingFactor: Floating = 1e-3
  override val name: String = "milli"
  override val abbreviation: String = "m"
}

sealed trait Single extends PrefixFrom {
  override type PrefixType = Single
  override implicit val classTag: ClassTag[Single] = implicitly[ClassTag[Single]]
  override protected final val floatingFactor: Floating = 1d
  override val name: String = ""
  override val abbreviation: String = ""
}

sealed trait Kilo extends PrefixFrom {
  override type PrefixType = Kilo
  override implicit val classTag: ClassTag[Kilo] = implicitly[ClassTag[Kilo]]
  override protected final val floatingFactor: Floating = 1e3
  override val name: String = "kilo"
  override val abbreviation: String = "k"
}
