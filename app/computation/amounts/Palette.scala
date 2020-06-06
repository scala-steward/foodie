package computation.amounts

import computation.base.Functional.Implicits._
import computation.base._
import computation.base.math.LeftModuleUtil.LeftModuleSelf
import computation.physical.NamedUnit.Implicits._
import spire.algebra.{LeftModule, Ring}
import spire.syntax.leftModule._

import scala.language.implicitConversions

case class Palette[N](masses: Functional[Mass[N], Nutrient with Type.MassBased],
                      units: Functional[IUnit[N], Nutrient with Type.IUBased],
                      energies: Functional[Energy[N], Nutrient with Type.EnergyBased])

object Palette {

  object Implicits {

    implicit def paletteLeftModule[L](implicit leftModuleMasses: LeftModule[Mass[L], L],
                                      leftModuleUnits: LeftModule[IUnit[L], L],
                                      leftModuleEnergies: LeftModule[Energy[L], L]): LeftModule[Palette[L], L] = new LeftModule[Palette[L], L] {
      override def scalar: Ring[L] = leftModuleMasses.scalar

      override def timesl(r: L, v: Palette[L]): Palette[L] =
        Palette(
          masses = r *: v.masses,
          units = r *: v.units,
          energies = r *: v.energies
        )

      override def negate(x: Palette[L]): Palette[L] =
        Palette(
          masses = -x.masses,
          units = -x.units,
          energies = -x.energies
        )

      override def zero: Palette[L] =
        Palette(
          masses = Functional(_ => leftModuleMasses.zero),
          units = Functional(_ => leftModuleUnits.zero),
          energies = Functional(_ => leftModuleEnergies.zero),
        )

      override def plus(x: Palette[L], y: Palette[L]): Palette[L] =
        Palette(
          masses = x.masses + y.masses,
          units = x.units + y.units,
          energies = x.energies + y.energies
        )
    }
  }


  def fromAssociations[N: LeftModuleSelf](massAssociations: Iterable[(Nutrient with Type.MassBased, Mass[N])],
                                          unitAssociations: Iterable[(Nutrient with Type.IUBased, IUnit[N])],
                                          energyAssociations: Iterable[(Nutrient with Type.EnergyBased, Energy[N])]): Palette[N] = {
    val masses = Functional.fromAssociations(massAssociations)
    val units = Functional.fromAssociations(unitAssociations)
    val energies = Functional.fromAssociations(energyAssociations)

    Palette(masses, units, energies)
  }

}