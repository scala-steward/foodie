import physical.NamedUnitAnyPrefix.Implicits._
import physical.PUnit.Syntax.Gram
import physical._
import spire.math.Numeric

package object base {

  type Mass[N, P] = NamedUnit[N, P, Gram]
  type Energy[N, P] = NamedUnit[N, P, Calorie]
  type IUnit[N, P] = NamedUnit[N, P, IU]

  object Mass {
    def apply[N: Numeric, P](physicalAmount: PhysicalAmount[N, P]): Mass[N, P] = {
      NamedUnit[N, P, Gram](physicalAmount)
    }
  }

  type Floating = BigDecimal

  type Weight = Floating

}
