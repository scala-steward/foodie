package computation.amounts

import algebra.ring.AdditiveMonoid
import computation.amounts.Palette.Implicits._
import computation.base.{Energy, IUnit, Mass}
import computation.base.Type.EnergyBased
import computation.base.math.LeftModuleUtil.Implicits._
import computation.physical.IU
import computation.physical.NamedUnit.Implicits._
import spire.algebra.{Field, LeftModule}
import spire.syntax.leftModule._

/**
 * The main type representing a recipe.
 * Put simply, a recipe is merely a list of amounts (of ingredients).
 * This simplification allows a very simple computation of the overall nutritional palette,
 * which is essentially the sum of the individual palettes of the amounts.
 *
 * @param ingredients The contents that are put in the recipe.
 *                    For simplicity, it is assumed that no nutrients are lost in the cooking process.
 */
case class Recipe[N: Field](ingredients: Iterable[AmountOf[N]]) {
  /**
   * The overall nutritional palette associated with this recipe.
   */
  val palette: Palette[N] = Recipe.palette(ingredients)

  def scale(factor: N): Palette[N] = factor *: palette
}

object Recipe {

  /**
   * Compute the sum of individual palettes from a list of ingredients.
   *
   * @param ingredients The ingredients of a recipe.
   * @return The nutritional content of the overall dish.
   */
  def palette[N: Field](ingredients: Iterable[AmountOf[N]]): Palette[N] = {
    val palettes: Iterable[Palette[N]] = ingredients.map(AmountOf.palette[N])
    // TODO: This explicit construction should not be necessary.
    implicit val massModule: LeftModule[Mass[N], N] = namedUnitLeftModule
    implicit val energyModule: LeftModule[Energy[N], N] = namedUnitLeftModule
    implicit val iUnitModule: LeftModule[IUnit[N], N] = namedUnitLeftModule
    implicit val paletteModule: LeftModule[Palette[N], N] = paletteLeftModule
    val resultPalette = AdditiveMonoid[Palette[N]].sum(palettes)
    resultPalette
  }
}

