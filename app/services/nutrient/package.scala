package services

package object nutrient {

  type NutrientMap = Map[Nutrient, BigDecimal]

  object NutrientMap {
    val empty: NutrientMap = Map.empty
  }

}
