package computation.amounts

import computation.base.Ingredient

/**
  * Certain things have an ingredient and this mixin denotes precisely this fact.
  * @tparam N The type of number used in the internal measurements.
  */
trait HasIngredient[N] {
  /**
    * @return The base ingredient
    */
  def ingredient: Ingredient[N]
}
