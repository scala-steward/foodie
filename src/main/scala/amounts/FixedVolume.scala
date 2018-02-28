package amounts

import base.Ingredient
import physical.PUnit.Syntax._
import physical.PhysicalAmount.Implicits._
import physical.{Milli, _}
import spire.implicits._
import spire.math.Numeric

import scala.reflect.ClassTag

/**
  * Certain amounts are prescribed in "vessels" of fixed size.
  *
  * @param hasVolume  A container of a fixed size.
  * @param ingredient The ingredient measured in this container.
  * @param units      The amount of containers used.
  * @tparam N The type of number used for the amounts.
  * @tparam P The type of the prefix.
  */
case class FixedVolume[N: Numeric, P <: Prefix : ClassTag](hasVolume: HasVolume[N, P],
                                                           override val ingredient: Ingredient[N],
                                                           override val units: N)
  extends ByVolume[N] with HasUnit[N] with HasIngredient[N] {

  override val litres: NamedUnit[N, P, Litre] = NamedUnit[N, P, Litre](units *: hasVolume.volume.amount)

}

object FixedVolume {

  private def mkLitre[N: Numeric, P <: Prefix : ClassTag](amount: N): NamedUnit[N, P, Litre] =
    NamedUnit[N, P, Litre](PhysicalAmount.fromRelative[N, P](amount))

  /**
    * A cup is a standard American measurement unit and corresponds to 250ml.
    *
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
