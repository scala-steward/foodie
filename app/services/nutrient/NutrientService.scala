package services.nutrient

import db.generated.Tables
import services.recipe.Ingredient
import services.{ FoodId, MeasureId }
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait NutrientService {

  def nutrientsOfFood(
      foodId: FoodId,
      measureId: Option[MeasureId],
      factor: BigDecimal
  ): Future[NutrientMap]

  def all: Future[Seq[Nutrient]]
}

object NutrientService {

  trait Companion {

    def nutrientsOfFood(
        foodId: FoodId,
        measureId: Option[MeasureId],
        amount: BigDecimal
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def nutrientsOfIngredient(
        ingredient: Ingredient
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def nutrientsOfIngredients(
        ingredients: Seq[Ingredient]
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit ec: ExecutionContext): DBIO[Tables.ConversionFactorRow]

    def all(implicit ec: ExecutionContext): DBIO[Seq[Nutrient]]
  }

}
