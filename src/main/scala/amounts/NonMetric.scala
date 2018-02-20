package amounts

import base.{Ingredient, Mass}
import physical.{PhysicalAmount, Prefix, Single}
import spire.implicits._
import spire.math.Numeric
import PhysicalAmount.Implicits._
import Prefix.Syntax._

abstract class NonMetric[N: Numeric](inGrams: PhysicalAmount[N, Single])
  extends Weighted[N] with HasUnit[N] with HasIngredient[N] {

  override def toMass[P: Prefix]: Mass[N, P] = {
    Mass(units *: inGrams.rescale[P])
  }
}

object NonMetric {

  case class Ounce[N: Numeric](override val ingredient: Ingredient[N],
                               override val units: N)
    extends NonMetric(PhysicalAmount.fromRelative[N, Single](Numeric[N].fromBigDecimal(29.4))) //todo: Ounce?

  case class Pound[N: Numeric](override val ingredient: Ingredient[N],
                               override val units: N)
    extends NonMetric(PhysicalAmount.fromRelative[N, Single](Numeric[N].fromBigDecimal(470))) //todo: Pound?
}
