package services.nutrient

import db.{ FoodId, MeasureId }
import services.recipe.Ingredient
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait NutrientService {

  def all: Future[Seq[Nutrient]]
}

object NutrientService {

  /** The case `measureId = None` means that the unit is "100g", i.e. no conversion is necessary. */
  case class ConversionFactorKey(
      foodId: FoodId,
      measureId: Option[MeasureId]
  )

  object ConversionFactorKey {

    def of(ingredient: Ingredient): ConversionFactorKey =
      ConversionFactorKey(
        ingredient.foodId,
        ingredient.amountUnit.measureId
      )

  }

  trait Companion {

    def nutrientsOfFood(
        foodId: FoodId,
        measureId: Option[MeasureId],
        amount: BigDecimal
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def nutrientsOfIngredients(
        ingredients: Seq[Ingredient]
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit ec: ExecutionContext): DBIO[BigDecimal]

    def conversionFactors(
        conversionFactorKeys: Seq[ConversionFactorKey]
    )(implicit ec: ExecutionContext): DBIO[Map[ConversionFactorKey, BigDecimal]]

    def all: DBIO[Seq[Nutrient]]
  }

}
