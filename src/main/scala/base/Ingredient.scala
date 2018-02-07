package base

trait Ingredient {

  /**
    * @return The nutritional palette of a given ingredient per the base reference mass (usually 100g).
    */
  def basePalette: Palette

  /**
    * @return The reference mass.
    *         Each amount of this ingredient contains precisely the nutritional values
    *         provided in [[basePalette]].
    */
  def baseReference: Mass

}
