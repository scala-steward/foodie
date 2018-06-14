package amounts

import algebra.ring.AdditiveSemigroup
import base.FunctionalAnyPrefix.Implicits._
import base.Nutrient.{EnergyBased, IUBased, MassBased}
import base._
import base.math.ScalarMultiplication
import base.math.ScalarMultiplication.Syntax._
import physical.NamedUnit.Implicits._
import physical.NamedUnitAnyPrefix
import physical.NamedUnitAnyPrefix.Implicits._
import physical.PUnit.Syntax._
import physical.PhysicalAmount.Implicits._
import spire.algebra.AdditiveMonoid
import spire.implicits._
import spire.math.Numeric

import scala.language.implicitConversions

case class Palette[N: Numeric](masses: Functional[Mass[N, _], Nutrient with Nutrient.MassBased],
                               units: Functional[IUnit[N, _], Nutrient with Nutrient.IUBased],
                               energies: Functional[Energy[N, _], Nutrient with Nutrient.EnergyBased])

object Palette {

  object Implicits {

    private class PaletteASG[N: Numeric] extends AdditiveSemigroup[Palette[N]] {
      override def plus(x: Palette[N], y: Palette[N]): Palette[N] = {
        Palette(x.masses + y.masses, x.units + y.units, x.energies + y.energies)
      }
    }

    private class PaletteAM[N: Numeric] extends PaletteASG[N] with AdditiveMonoid[Palette[N]] {
      override def zero: Palette[N] = Palette(
        implicitly(AdditiveMonoid[Functional[Mass[N, _], Nutrient with Nutrient.MassBased]]).zero,
        implicitly(AdditiveMonoid[Functional[IUnit[N, _], Nutrient with Nutrient.IUBased]]).zero,
        implicitly(AdditiveMonoid[Functional[Energy[N, _], Nutrient with Nutrient.EnergyBased]]).zero
      )
    }

    private class PaletteSM[R: Numeric, N: Numeric](implicit sm: ScalarMultiplication[R, N])
      extends ScalarMultiplication[R, Palette[N]] {

      private implicit val mass: ScalarMultiplication[R, Functional[Mass[N, _], Nutrient with Nutrient.MassBased]] =
        Functional.Implicits.scalarMultiplicationF[R, Mass[N, _], Nutrient with Nutrient.MassBased]

      private implicit val unit: ScalarMultiplication[R, Functional[IUnit[N, _], Nutrient with Nutrient.IUBased]] =
        Functional.Implicits.scalarMultiplicationF[R, IUnit[N, _], Nutrient with Nutrient.IUBased]

      private implicit val energy: ScalarMultiplication[R, Functional[Energy[N, _], Nutrient with Nutrient.EnergyBased]] =
        Functional.Implicits.scalarMultiplicationF[R, Energy[N, _], Nutrient with Nutrient.EnergyBased]

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


  def fromAssociations[N: Numeric](massAssociations: Iterable[(Nutrient with MassBased, Mass[N, _])],
                                   unitAssociations: Iterable[(Nutrient with IUBased, IUnit[N, _])],
                                   energyAssociations: Iterable[(Nutrient with EnergyBased, Energy[N, _])]): Palette[N] = {
    val masses = Functional.fromAssociations(massAssociations)
    val units = Functional.fromAssociations(unitAssociations)
    val energies = Functional.fromAssociations(energyAssociations)

    Palette(
      masses,
      units,
      energies
    )
  }

}