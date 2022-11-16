package services

import services.nutrient.Nutrient

package object stats {

  type NutrientAmountMap = Map[Nutrient, Amount]
}
