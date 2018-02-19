package base

class Palette[N: Numeric](amounts: Nutrient => Mass[N, _]) extends (Nutrient => Mass[N, _]) {
  override def apply(nutrient: Nutrient): Mass[N, _] = amounts(nutrient)

}
