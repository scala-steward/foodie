package amounts

import base.{Ingredient, Mass}
import physical.PUnit.Syntax.Litre
import physical.PhysicalAmount.Implicits._
import physical.Prefix.Syntax._
import physical.{Milli, _}
import spire.implicits._
import spire.math.Numeric

/**
  * Certain amounts are prescribed in "vessels" of fixed size.
  * @param hasVolume A container of a fixed size.
  * @param ingredient The ingredient measured in this container.
  * @param units The amount of containers used.
  * @tparam N The type of number used for the amounts.
  * @tparam P The type of the prefix.
  */
case class FixedVolume[N: Numeric, P: Prefix](hasVolume: HasVolume[N, P],
                                              override val ingredient: Ingredient[N],
                                              override val units: N)
  extends ByVolume[N] with HasUnit[N] with HasIngredient[N] {

  override def weightOfMillilitre[Q: Prefix]: Mass[N, Q] = ingredient.weightPerMillilitre[Q]

  override val litres: NamedUnit[N, P, Litre] = NamedUnit(units *: hasVolume.volume.amount, Litre)

}

object FixedVolume {

  private def mkLitre[N: Numeric, P: Prefix](amount: N): NamedUnit[N, P, Litre] =
    NamedUnit(PhysicalAmount.fromRelative[N, P](amount), Litre)

  /**
    * A cup is a standard American measurement unit and corresponds to 250ml.
    * @tparam N The type of number used in the measurement.
    */
  case class Cup[N: Numeric]() extends HasVolume[N, Milli] {
    override val volume: NamedUnit[N, Milli, Litre] = mkLitre[N, Milli](250)
  }

  case class Teaspoon[N: Numeric]() extends HasVolume[N, Milli] {
    override val volume: NamedUnit[N, Milli, Litre] = mkLitre[N, Milli](5)
  }

  case class Tablespoon[N: Numeric]() extends HasVolume[N, Milli] {
    override val volume: NamedUnit[N, Milli, Litre] = mkLitre[N, Milli](15)
  }

}
