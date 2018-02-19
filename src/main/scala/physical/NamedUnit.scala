package physical

import spire.math.Numeric

case class NamedUnit[N: Numeric, P, U <: PUnit](amount: PhysicalAmount[N, P], unit: U) {

  override val toString: String = NamedUnit.mkString(_.name, _.name)(amount, unit)

  val abbreviated: String = NamedUnit.mkString(_.abbreviation, _.abbreviation)(amount, unit)

  lazy val normalised: NamedUnit[N, _, U] = {
    val total = amount.normalise
    NamedUnit(total, unit)
  }
}

object NamedUnit {
  private def mkString(prefixName: Prefix[_] => String, unitName: PUnit => String)
                      (amount: PhysicalAmount[_, _], unit: PUnit): String = {
    s"${amount.relative} ${prefixName(amount.prefix)}${unitName(unit)}"
  }
}