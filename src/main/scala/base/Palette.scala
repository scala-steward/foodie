package base

class Palette(amounts: Nutrient => Mass) extends (Nutrient => Mass) {
  override def apply(nutrient: Nutrient): Mass = amounts(nutrient)

}
