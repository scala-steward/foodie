package amounts

import base.Ingredient

trait HasIngredient[N] {
  def ingredient: Ingredient[N]
}
