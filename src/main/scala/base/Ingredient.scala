package base

import physical.Prefix
import spire.math.Numeric

trait Ingredient[N] {

  implicit val numeric: Numeric[N]

  /**
    * @return The nutritional palette of a given ingredient per the base reference mass (usually 100g).
    */
  def basePalette: Palette[N]

  /**
    * @return The reference mass.
    *         Each amount of this ingredient contains precisely the nutritional values
    *         provided in [[basePalette]].
    */
  def baseReference: Mass[N, _]

  def weightPerMillilitre[P: Prefix]: Mass[N, P]
}
