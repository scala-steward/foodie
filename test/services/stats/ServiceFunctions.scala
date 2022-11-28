package services.stats

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl._
import services._
import services.recipe.{ Ingredient, Recipe }
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ServiceFunctions {

  def computeNutrientAmount(
      nutrientId: NutrientId,
      ingredients: Seq[Ingredient]
  ): DBIO[Option[(Int, BigDecimal)]] = {
    val transformer =
      for {
        conversionFactors <-
          ingredients
            .traverse { ingredient =>
              OptionT
                .fromOption[DBIO](ingredient.amountUnit.measureId)
                .subflatMap(measureId => StatsGens.allConversionFactors.get((ingredient.foodId, measureId)))
                .orElseF(DBIO.successful(Some(BigDecimal(1))))
                .map(ingredient.id -> _)
            }
            .map(_.toMap)
        nutrientAmounts <- OptionT.liftF(nutrientAmountOf(nutrientId, ingredients.map(_.foodId)))
        ingredientAmounts = ingredients.flatMap { ingredient =>
          nutrientAmounts.get(ingredient.foodId).map { nutrientAmount =>
            nutrientAmount *
              ingredient.amountUnit.factor *
              conversionFactors(ingredient.id)
          }
        }
        amounts <- OptionT.fromOption[DBIO](Some(ingredientAmounts).filter(_.nonEmpty))
      } yield (nutrientAmounts.keySet.size, amounts.sum)

    transformer.value
  }

  def nutrientAmountOf(
      nutrientId: NutrientId,
      foodIds: Seq[FoodId]
  ): DBIO[Map[FoodId, BigDecimal]] = {
    val baseMap = Tables.NutrientAmount
      .filter(na =>
        na.nutrientId === nutrientId.transformInto[Int]
          && na.foodId.inSetBind(foodIds.map(_.transformInto[Int]))
      )
      .result
      .map { nutrientAmounts =>
        nutrientAmounts
          .map(na => na.foodId.transformInto[FoodId] -> na.nutrientValue)
          .toMap
      }
    /* The constellation of foodId = 534 and nutrientId = 339 has no entry in the
       amount table, but there is an entry referencing the non-existing nutrientId = 328,
       with the value 0.1.
       There is no nutrient with id 328, but there is one nutrient with the *code* 328,
       and this nutrient has the id 339.
       The assumption is that this reference has been added by mistake,
       hence we correct this mistake here.
     */
    val erroneousNutrientId = 339.transformInto[NutrientId]
    val erroneousFoodId     = 534.transformInto[FoodId]
    if (nutrientId == erroneousNutrientId && foodIds.contains(erroneousFoodId)) {
      baseMap.map(_.updated(erroneousFoodId, BigDecimal(0.1)))
    } else {
      baseMap
    }
  }

  def computeNutrientAmounts(
      recipe: Recipe,
      ingredients: List[Ingredient]
  ): Future[Map[NutrientId, Option[(Int, BigDecimal)]]] = {
    DBTestUtil.dbRun {
      StatsGens.allNutrients
        .traverse { nutrient =>
          computeNutrientAmount(nutrient.id, ingredients)
            .map(v =>
              nutrient.id ->
                v.map { case (number, value) => number -> value / recipe.numberOfServings }
            ): DBIO[(NutrientId, Option[(Int, BigDecimal)])]
        }
        .map(_.toMap)
    }
  }

}
