package services.nutrient

import db.{ FoodId, MeasureId }
import services.recipe.Ingredient
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait NutrientService {

  def all: Future[Seq[Nutrient]]
}

object NutrientService {

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

    def all: DBIO[Seq[Nutrient]]
  }

}
