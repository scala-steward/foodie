package computation

import computation.physical.PUnit.Syntax.Gram
import computation.physical._

package object base {

  type Mass[N] = NamedUnit[N, Gram]
  type Energy[N] = NamedUnit[N, Calorie]
  type IUnit[N] = NamedUnit[N, IU]

  object Mass {
    def apply[N](physicalAmount: PhysicalAmount[N]): Mass[N] = {
      NamedUnit[N, Gram](physicalAmount)
    }
  }

  type Floating = BigDecimal

  type Weight = Floating

}
