package amounts

import algebra.ring.AdditiveSemigroup
import base.FunctionalAnyPrefix.Implicits._
import base._
import base.math.ScalarMultiplication
import base.math.ScalarMultiplication.Syntax._
import physical.NamedUnit.Implicits._
import physical.NamedUnitAnyPrefix.Implicits._
import physical.PUnit.Syntax._
import physical.PhysicalAmount.Implicits._
import spire.algebra.AdditiveMonoid
import spire.implicits._
import spire.math.Numeric

import scala.language.implicitConversions

case class Palette[N: Numeric](masses: Functional[Mass[N, _], Nutrient with Type.MassBased],
                               units: Functional[IUnit[N, _], Nutrient with Type.IUBased],
                               energies: Functional[Energy[N, _], Nutrient with Type.EnergyBased]) {
  override val toString: String = {
    def show[R, A](functional: Functional[R, A], all: Traversable[A]): String =
      all.map { n => s"$n -> ${functional(n)}" }.mkString("\n")

    s"Palette(\n${show(masses, Type.MassBased.all)}\n" +
      s"${show(units, Type.IUBased.all)}\n" +
      s"${show(energies, Type.EnergyBased.all)}\n)"
  }
}

object Palette {

  object Implicits {

    private class PaletteASG[N: Numeric] extends AdditiveSemigroup[Palette[N]] {
      override def plus(x: Palette[N], y: Palette[N]): Palette[N] = {
        Palette(x.masses + y.masses, x.units + y.units, x.energies + y.energies)
      }
    }

    private class PaletteAM[N: Numeric] extends PaletteASG[N] with AdditiveMonoid[Palette[N]] {
      override def zero: Palette[N] = Palette(
        implicitly(AdditiveMonoid[Functional[Mass[N, _], Nutrient with Type.MassBased]]).zero,
        implicitly(AdditiveMonoid[Functional[IUnit[N, _], Nutrient with Type.IUBased]]).zero,
        implicitly(AdditiveMonoid[Functional[Energy[N, _], Nutrient with Type.EnergyBased]]).zero
      )
    }

    private class PaletteSM[R: Numeric, N: Numeric](implicit sm: ScalarMultiplication[R, N])
      extends ScalarMultiplication[R, Palette[N]] {

      private implicit val mass: ScalarMultiplication[R, Functional[Mass[N, _], Nutrient with Type.MassBased]] =
        Functional.Implicits.scalarMultiplicationF[R, Mass[N, _], Nutrient with Type.MassBased]

      private implicit val unit: ScalarMultiplication[R, Functional[IUnit[N, _], Nutrient with Type.IUBased]] =
        Functional.Implicits.scalarMultiplicationF[R, IUnit[N, _], Nutrient with Type.IUBased]

      private implicit val energy: ScalarMultiplication[R, Functional[Energy[N, _], Nutrient with Type.EnergyBased]] =
        Functional.Implicits.scalarMultiplicationF[R, Energy[N, _], Nutrient with Type.EnergyBased]

      override def scale(scalar: R, vector: Palette[N]): Palette[N] = Palette(
        vector.masses.scale(scalar)(mass),
        vector.units.scale(scalar)(unit),
        vector.energies.scale(scalar)(energy)
      )
    }

    implicit def paletteASG[N: Numeric]: AdditiveSemigroup[Palette[N]] = new PaletteASG[N]

    implicit def paletteAM[N: Numeric]: AdditiveMonoid[Palette[N]] = new PaletteAM[N]

    implicit def paletteSM[R: Numeric, N: Numeric](implicit sm: ScalarMultiplication[R, N]): ScalarMultiplication[R, Palette[N]] =
      new PaletteSM[R, N]

  }


  def fromAssociations[N: Numeric](massAssociations: Traversable[(Nutrient with Type.MassBased, Mass[N, _])],
                                   unitAssociations: Traversable[(Nutrient with Type.IUBased, IUnit[N, _])],
                                   energyAssociations: Traversable[(Nutrient with Type.EnergyBased, Energy[N, _])]): Palette[N] = {
    val masses = Functional.fromAssociations(massAssociations)
    val units = Functional.fromAssociations(unitAssociations)
    val energies = Functional.fromAssociations(energyAssociations)

    Palette(masses, units, energies)
  }

}