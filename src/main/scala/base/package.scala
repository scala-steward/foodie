import physical.PUnit.Syntax.Gram
import physical._
import spire.math.Numeric

package object base {

  type Mass[N, P] = NamedUnit[N, P, Gram]

  object Mass {
    def apply[N: Numeric, P](physicalAmount: PhysicalAmount[N, P]): Mass[N, P] = {
      NamedUnit[N, P, Gram](physicalAmount)
    }
  }

  type Palette[N] = Functional[Mass[N, _], Nutrient]

  type Floating = BigDecimal

  type Weight = Floating

}
