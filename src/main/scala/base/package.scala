package object base {

//  type Palette = Nutrient => Mass

  type Mass = UnitWithPrefix[Floating, _]

  type Floating = BigDecimal

  type Weight = Floating

}
