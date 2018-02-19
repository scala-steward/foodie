import physical.PUnit.Syntax.Gram
import physical.{Gram, NamedUnit, PhysicalAmount}
import spire.math.Numeric

package object base {

//  type Palette = Nutrient => Mass

  type Mass[N, P] = NamedUnit[N, P, Gram]

  object Mass {
    def apply[N: Numeric, P](physicalAmount: PhysicalAmount[N, P]): Mass[N, P] = {
      NamedUnit[N, P, Gram](physicalAmount, Gram)
    }
  }

  type Floating = BigDecimal

  type Weight = Floating

}
