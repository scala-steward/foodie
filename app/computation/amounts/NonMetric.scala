package computation.amounts

import computation.base.math.LeftModuleUtil.Implicits._
import computation.base.math.LeftModuleUtil.LeftModuleSelf
import computation.base.{Ingredient, Mass}
import computation.physical.PhysicalAmount
import computation.physical.PhysicalAmount.Implicits._
import spire.algebra.Field
import spire.syntax.leftModule._

abstract class NonMetric[N: LeftModuleSelf](inGrams: PhysicalAmount[N])
  extends Weighted[N] with HasUnit[N] with HasIngredient[N] {

  override lazy val mass: Mass[N] = Mass(units *: inGrams)
}

object NonMetric {

  private def fromGrams[F](grams: Double)(implicit field: Field[F]): PhysicalAmount[F] =
    PhysicalAmount(field.fromDouble(grams))

  case class Ounce[F: Field](override val ingredient: Ingredient[F],
                             override val units: F)
    extends NonMetric(fromGrams(28.3495))

  case class Pound[F: Field](override val ingredient: Ingredient[F],
                             override val units: F)
    extends NonMetric(fromGrams(453.592))

}
