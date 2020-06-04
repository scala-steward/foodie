package amounts

import base._
import base.math.ScalarMultiplication.Syntax._
import physical.NamedUnitAnyPrefix.Implicits._
import physical.PhysicalAmount.Implicits._
import Functional.Implicits._
import physical.NamedUnit.Implicits._
import spire.math.Numeric
import Palette.Implicits._

/**
  * The main type representing a recipe.
  * Put simply, a recipe is merely a list of amounts (of ingredients).
  * This simplification allows a very simple computation of the overall nutritional palette,
  * which is essentially the sum of the individual palettes of the amounts.
  *
  * @param ingredients The contents that are put in the recipe.
  *                    For simplicity, it is assumed that no nutrients are lost in the cooking process.
  * @tparam N The type of number in which the amounts are denoted (usually [[base.Floating]].
  */
case class Recipe[N: Numeric](ingredients: Traversable[AmountOf[N]]) {
  /**
    * The overall nutritional palette associated with this recipe.
    */
  val palette: Palette[N] = Recipe.palette(ingredients)

  def scale(factor: N): Palette[N] = palette.scale(factor)
}

object Recipe {

  /**
    * Compute the sum of individual palettes from a list of ingredients.
    *
    * @param ingredients The ingredients of a recipe.
    * @tparam N The numeric type in which the amounts are given.
    * @return The nutritional content of the overall dish.
    */
  def palette[N: Numeric](ingredients: Traversable[AmountOf[N]]): Palette[N] = {
    val palettes: Traversable[Palette[N]] = ingredients.map(AmountOf.palette[N])
    val resultPalette = CollectionUtil.sum(palettes)
    resultPalette
  }
}
