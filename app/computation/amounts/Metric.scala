package computation.amounts

import computation.base.{Ingredient, Mass}

case class Metric[N](override val mass: Mass[N],
                     override val ingredient: Ingredient[N]) extends Weighted[N]
