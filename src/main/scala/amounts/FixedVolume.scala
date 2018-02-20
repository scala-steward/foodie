package amounts

import base.{Ingredient, Mass}
import physical.PhysicalAmount.Implicits._
import physical.Prefix.Syntax._
import physical.{Milli, PhysicalAmount, Prefix}
import spire.implicits._
import spire.math.Numeric

abstract class FixedVolume[N: Numeric, P: Prefix](val volume: PhysicalAmount[N, P])
  extends ByVolume[N] with HasUnit[N] with HasIngredient[N] {

  override def weightOfMillilitre[Q: Prefix]: Mass[N, Q] = ingredient.weightPerMillilitre[Q]

  override val litres: PhysicalAmount[N, P] = units *: volume

}

object FixedVolume {

  case class Cup[N: Numeric](override val ingredient: Ingredient[N],
                             override val units: N)
    extends FixedVolume(PhysicalAmount.fromRelative[N, Milli](250))

  case class Teaspoon[N: Numeric](override val ingredient: Ingredient[N],
                                  override val units: N)
    extends FixedVolume(PhysicalAmount.fromRelative[N, Milli](2)) //todo: How big is a teaspoon?

  case class Tablespoon[N: Numeric](override val ingredient: Ingredient[N],
                                    override val units: N)
    extends FixedVolume(PhysicalAmount.fromRelative[N, Milli](5)) //todo: How big is a tablespoon?
}
