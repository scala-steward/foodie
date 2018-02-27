package amounts

import algebra.ring.AdditiveMonoid
import base.{Functional, FunctionalAnyPrefix, Nutrient, Palette}
import physical.NamedUnitAnyPrefix.Implicits._
import physical.PUnit.Syntax._
import physical.{Gram, NamedUnit, Prefix}
import spire.algebra.Module
import spire.implicits._
import spire.math.Numeric

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
}

object Recipe {
  private implicit def module[N: Numeric]: Module[Functional[NamedUnit[N, _ <: Prefix, Gram], Nutrient], N] =
    FunctionalAnyPrefix.Implicits.fapM[Nutrient, N, Gram]

  /**
    * Compute the sum of individual palettes from a list of ingredients.
    *
    * @param ingredients The ingredients of a recipe.
    * @tparam N The numeric type in which the amounts are given.
    * @return The nutritional content of the overall dish.
    */
  def palette[N: Numeric](ingredients: Traversable[AmountOf[N]]): Palette[N] = {
    val palettes: Traversable[Palette[N]] = ingredients.map(AmountOf.palette[N])
    val resultPalette = palettes.foldLeft(AdditiveMonoid[Palette[N]].zero)(_ + _)
    resultPalette
  }
}