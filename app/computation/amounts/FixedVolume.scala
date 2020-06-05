package computation.amounts

import computation.base.Ingredient
import computation.base.math.LeftModuleUtil.LeftModuleSelf
import computation.physical.PhysicalAmount.Implicits._
import computation.physical._
import spire.algebra.Field
import spire.implicits._

/**
  * Certain amounts are prescribed in "vessels" of fixed size.
  *
  * @param hasVolume  A container of a fixed size.
  * @param ingredient The ingredient measured in this container.
  * @param units      The amount of containers used.
  * @tparam N The type of number used for the amounts.
  */
case class FixedVolume[N: LeftModuleSelf](hasVolume: HasVolume[N],
                                          override val ingredient: Ingredient[N],
                                          override val units: N)
  extends ByVolume[N] with HasUnit[N] with HasIngredient[N] {

  override val litres: NamedUnit[N, Litre] = NamedUnit[N, Litre](units *: hasVolume.volume.amount)

}

object FixedVolume {

  private def fromMillilitres[F](millilitres: Int)
                                (implicit field: Field[F]): NamedUnit[F, Litre] = {
    val asLitres = field.fromInt(millilitres) / field.fromInt(1000)
    NamedUnit(PhysicalAmount(asLitres))
  }

  /**
    * A cup is a standard American measurement unit and corresponds to 250ml.
    *
    * @tparam F The type of number used in the measurement.
    */
  case class Cup[F: Field]() extends HasVolume[F] {
    override val volume: NamedUnit[F, Litre] = fromMillilitres[F](250)
  }

  case class Teaspoon[N: Field]() extends HasVolume[N] {
    override val volume: NamedUnit[N, Litre] = fromMillilitres[N](5)
  }

  case class Tablespoon[N: Field]() extends HasVolume[N] {
    override val volume: NamedUnit[N, Litre] = fromMillilitres[N](15)
  }

}
