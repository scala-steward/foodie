package services.nutrient

import db.{ FoodId, NutrientCode }
import io.scalaland.chimney.dsl._
import services.common.GeneralTableConstants
import utils.TransformerUtils.Implicits._

import javax.inject.{ Inject, Singleton }

@Singleton
class NutrientTableConstants @Inject() (
    generalTableConstants: GeneralTableConstants
) {

  val allNutrientMaps: Map[FoodId, NutrientMap] = {
    val byNutrientId   = generalTableConstants.allNutrientNames.map(n => n.nutrientNameId -> n).toMap
    val byNutrientCode = generalTableConstants.allNutrientNames.map(n => n.nutrientCode -> n).toMap

    generalTableConstants.allNutrientAmounts
      .groupBy(na => na.foodId)
      .map { case (foodId, amounts) =>
        val typedFoodId = foodId.transformInto[FoodId]
        typedFoodId -> amounts.flatMap { nutrientAmount =>
          byNutrientId
            .get(nutrientAmount.nutrientId)
            .orElse(byNutrientCode.get(nutrientAmount.nutrientId))
            .map(name =>
              name.transformInto[Nutrient] -> AmountEvaluation.embed(nutrientAmount.nutrientValue, typedFoodId)
            )
        }.toMap
      }
  }

  val allNutrients: Map[NutrientCode, Nutrient] =
    generalTableConstants.allNutrientNames.map { nutrientName =>
      val nutrient = nutrientName.transformInto[Nutrient]
      nutrient.code -> nutrient
    }.toMap

}
