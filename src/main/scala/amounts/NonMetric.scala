package amounts

import base.{Ingredient, Mass}
import physical.PhysicalAmount.Implicits._
import physical.Prefix.Syntax._
import physical.{PhysicalAmount, Prefix, Single}
import spire.implicits._
import spire.math.Numeric

abstract class NonMetric[N: Numeric](inGrams: PhysicalAmount[N, Single])
  extends Weighted[N] with HasUnit[N] with HasIngredient[N] {

  override def toMass[P: Prefix]: Mass[N, P] = {
    Mass(units *: inGrams.rescale[P])
  }
}

object NonMetric {

  private def mkAmount[N: Numeric, P: Prefix](amount: Double): PhysicalAmount[N, P] =
    PhysicalAmount.fromRelative[N, P](Numeric[N].fromBigDecimal(amount))

  case class Ounce[N: Numeric](override val ingredient: Ingredient[N],
                               override val units: N)
    extends NonMetric(mkAmount(28.3495))

  case class Pound[N: Numeric](override val ingredient: Ingredient[N],
                               override val units: N)
    extends NonMetric(mkAmount(453.592))
}
