package amounts

import algebra.ring.AdditiveMonoid
import base.FunctionalAnyPrefix.Implicits._
import base.Mineral.Iron
import base.Trace.Tryptophane
import base.Vitamin.VitaminC
import base._
import physical.NamedUnitAnyPrefix.Implicits._
import physical.PUnit.Syntax._
import physical.PhysicalAmount.Implicits._
import physical.Prefix.Syntax._
import physical._
import spire.algebra.AdditiveSemigroup
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

object TestMe {

  def main(args: Array[String]): Unit = {

    val pa = PhysicalAmount.fromRelative[Floating, Single](100)(Numeric[Floating], Single)
    val base: Mass[Floating, Single] = Mass(pa)

    val ingredient1 = new Ingredient[Floating] {
      override val basePalette: Palette[Floating] = new Functional[Mass[Floating, _], Nutrient]({
        case Iron => Mass(PhysicalAmount.fromRelative[Floating, Milli](5)) //=> 11.75 milligram 0.01175
        case VitaminC => Mass(PhysicalAmount.fromRelative[Floating, Single](3))
        case Tryptophane => Mass(PhysicalAmount.fromRelative[Floating, Micro](17))
      }
      )

      override val baseReference: Mass[Floating, _] = base

      override def weightPerMillilitre[P: Prefix]: Mass[Floating, P] =
        Mass(PhysicalAmount.fromAbsolute[Floating, P](0.470))
    }

    val ingredient2 = new Ingredient[Floating] {
      override val basePalette: Palette[Floating] = new Functional[Mass[Floating, _], Nutrient]({
        case Iron => Mass(PhysicalAmount.fromRelative[Floating, Micro](16)) //=> 48 microgram 0.000048
        case VitaminC => Mass(PhysicalAmount.fromRelative[Floating, Milli](1))
        case Tryptophane => Mass(PhysicalAmount.fromRelative[Floating, Nano](3))
      }
      )

      override val baseReference: Mass[Floating, _] = base

      override def weightPerMillilitre[P: Prefix]: Mass[Floating, P] =
        Mass(PhysicalAmount.fromAbsolute[Floating, P](1.3))
    }

    val ingredients = List(
      FixedVolume[Floating, Milli](FixedVolume.Cup[Floating](), ingredient1, 2),
      Metric(Mass(PhysicalAmount.fromRelative[Floating, Single](300)), ingredient2)
    )

    val recipe = Recipe(ingredients)
    val pal = recipe.palette

    println(
      s"iron = ${pal(Iron)}, vitaminC = ${pal(VitaminC)}, tryptophane = ${pal(Tryptophane)}")

    val nu1: NamedUnit[Floating, _, Gram] = Mass(PhysicalAmount.fromRelative[Floating, Milli](100))
    val nu2: NamedUnit[Floating, _, Gram] = Mass(PhysicalAmount.fromRelative[Floating, Nano](5))

    import NamedUnitAnyPrefix.Implicits._


    implicit val asg: AdditiveSemigroup[NamedUnit[Floating, _, Gram]] = NamedUnitAnyPrefix.Implicits.additiveSemigroupNUAP
    println(asg.plus(nu1, nu2))
  }
}