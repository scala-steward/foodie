package services

import shapeless.tag.@@

package object nutrient {

  sealed trait NutrientTag

  type NutrientId = Int @@ NutrientTag

  sealed trait NutrientCodeTag

  type NutrientCode = Int @@ NutrientCodeTag
}
