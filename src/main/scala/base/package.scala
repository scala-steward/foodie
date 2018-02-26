import physical.PUnit.Syntax.Gram
import physical._
import spire.math.Numeric

import scala.reflect.ClassTag

package object base {

  type Mass[N, P <: Prefix] = NamedUnit[N, P, Gram]

  object Mass {
    def apply[N: Numeric, P <: Prefix: ClassTag](physicalAmount: PhysicalAmount[N, P]): Mass[N, P] = {
      NamedUnit[N, P, Gram](physicalAmount)
    }
  }

  type Palette[N] = Functional[Mass[N, _ <: Prefix], Nutrient]

  type Floating = BigDecimal

  type Weight = Floating

}
