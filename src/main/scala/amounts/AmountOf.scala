package amounts

import algebra.ring.{AdditiveGroup, AdditiveMonoid}
import base._
import physical.PhysicalAmount.Implicits._
import physical.Prefix.Syntax._
import physical.{Milli, Single, _}
import spire.algebra.{Module, Rng}
import spire.implicits._
import spire.math.Numeric

import scala.reflect.ClassTag
import scalaz.Tag

/**
  * Denotes a certain amount of something.
  * Every amount can be converted to a mass with a certain prefix.
  *
  * @tparam N The type of number used for the amounts.
  */
sealed trait AmountOf[N] {

  /**
    * @return The ingredient whose amount is measured.
    */
  def ingredient: Ingredient[N]

  /**
    * @tparam P The prefix type.
    * @return The mass associated with the given amount.
    */
  def toMass[P <: Prefix: ClassTag]: Mass[N, P]
}

/**
  * Certain amounts are given in units of a fixed volume size.
  * This class is a base for these amounts.
  *
  * @tparam N The type of number used for the amounts.
  */
abstract class ByVolume[N: Numeric] extends AmountOf[N] {

  /**
    * @return The amount of litres associated with the given unit.
    */
  def litres: NamedUnit[N, _ <: Prefix, Litre]

  override def toMass[P <: Prefix: ClassTag]: Mass[N, P] = {
    val actual = Tag.unwrap(litres.amount.rescale[Milli].relative) *: ingredient.weightPerMillilitre[P].amount
    Mass(actual)
  }
}

/**
  * Aside from volume amounts there are amounts based upon weights.
  * This is a common super type for these amounts.
  * @tparam N The type of number used for the amounts.
  */
trait Weighted[N] extends AmountOf[N]

object AmountOf {


  def palette[N: Numeric](amount: AmountOf[N]): Palette[N] = {

    implicit def mod: Module[PhysicalAmount[N, _ <: Prefix], N] = new Module[PhysicalAmount[N, _ <: Prefix], N] {
      override val scalar: Rng[N] = Rng[N]

      override def timesl(r: N, v: PhysicalAmount[N, _ <: Prefix]): PhysicalAmount[N, _ <: Prefix] = ???

      override def negate(x: PhysicalAmount[N, _ <: Prefix]): PhysicalAmount[N, _ <: Prefix] = ???

      override def zero: PhysicalAmount[N, _ <: Prefix] = ???

      override def plus(x: PhysicalAmount[N, _ <: Prefix], y: PhysicalAmount[N, _ <: Prefix]): PhysicalAmount[N, _ <: Prefix] = ???
    }

    import PUnit.Syntax.Gram

//    implicit def mod: Module[Palette[N], N] =
//      Functional.Implicits.moduleF[Mass[N, P with Prefix[P] forSome { type P }], Nutrient, N](Rng[N], modM[Gram])
//
//    val base = amount.ingredient.basePalette
//    val reference = amount.ingredient.baseReference.amount.absolute
//    val given = amount.toMass[Single].amount.absolute
//    val factor = given / reference
//    factor *: base
    ???
  }

}