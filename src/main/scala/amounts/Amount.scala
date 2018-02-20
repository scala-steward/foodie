package amounts

import base.Mass
import physical.PhysicalAmount.Implicits._
import physical.Prefix.Syntax._
import physical.{Milli, _}
import spire.implicits._
import spire.math.Numeric

import scalaz.Tag

/**
  * Denotes a certain amount of something.
  * Every amount can be converted to a mass with a certain prefix.
  *
  * @tparam N The type of number used for the amounts.
  */
sealed trait Amount[N] {

  /**
    * @tparam P The prefix type.
    * @return The mass associated with the given amount.
    */
  def toMass[P: Prefix]: Mass[N, P]
}

/**
  * Certain amounts are given in units of a fixed volume size.
  * This class is a base for these amounts.
  *
  * @tparam N The type of number used for the amounts.
  */
abstract class ByVolume[N: Numeric] extends Amount[N] {

  /**
    * @tparam P The type of prefix.
    * @return The density of the ingredient that is measured.
    *
    */
  def weightOfMillilitre[P: Prefix]: Mass[N, P]

  /**
    * @return The amount of litres associated with the given unit.
    */
  def litres: NamedUnit[N, _, Litre]

  override def toMass[P: Prefix]: Mass[N, P] = {
    val actual = Tag.unwrap(litres.amount.rescale[Milli].relative) *: weightOfMillilitre[P].amount
    Mass(actual)
  }
}

/**
  * Aside from volume amounts there are amounts based upon weights.
  * This is a common super type for these amounts.
  * @tparam N The type of number used for the amounts.
  */
trait Weighted[N] extends Amount[N]


