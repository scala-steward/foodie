package recipes

import amounts.AmountOf
import base.Palette

case class Recipe[N: Numeric](ingredients: Iterable[AmountOf[N]]) {

  def palette: Palette[N] = {
???
  }

}
