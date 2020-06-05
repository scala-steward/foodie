package computation.amounts

import computation.amounts.Palette.Implicits._
import computation.base._
import computation.base.math.LeftModuleUtil.Implicits._
import computation.base.math.LeftModuleUtil.LeftModuleSelf
import computation.physical.NamedUnit.Implicits._
import computation.physical.{Litre, NamedUnit}
import spire.algebra.{Field, LeftModule}
import spire.syntax.field._
import spire.syntax.leftModule._

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
    * @return The mass associated with the given amount.
    */
  def toMass: Mass[N]
}

/**
  * Certain amounts are given in units of a fixed volume size.
  * This class is a base for these amounts.
  *
  * @tparam N The type of number used for the amounts.
  */
abstract class ByVolume[N: LeftModuleSelf] extends AmountOf[N] {

  /**
    * @return The amount of litres associated with the given unit.
    */
  def litres: NamedUnit[N, Litre]

  override def toMass: Mass[N] =
    LeftModuleSelf[N].scalar.fromInt(1000) *: litres.amount.value *: ingredient.weightPerMillilitre
}

/**
  * Aside from volume amounts there are amounts based upon weights.
  * This is a common super type for these amounts.
  *
  * @tparam N The type of number used for the amounts.
  */
trait Weighted[N] extends AmountOf[N]

object AmountOf {

  def palette[N: Field](amount: AmountOf[N]): Palette[N] = {
    val base = amount.ingredient.basePalette
    val reference = amount.ingredient.baseReference.amount.value
    val given = amount.toMass.amount.value
    val factor = given / reference
    LeftModule[Palette[N], N].timesl(factor, base)
  }

}