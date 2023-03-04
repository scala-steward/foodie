package services.nutrient

import db.generated.Tables
import db.{ FoodId, MeasureId, NutrientCode }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import javax.inject.{ Inject, Singleton }
import scala.concurrent.duration._
import scala.concurrent.{ Await, ExecutionContext }

@Singleton
class FullTableConstants @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider
)(implicit executionContext: ExecutionContext)
    extends HasDatabaseConfigProvider[PostgresProfile] {

  val allNutrientMaps: Map[FoodId, NutrientMap] = compute {
    for {
      allNutrientNames   <- Tables.NutrientName.result
      allNutrientAmounts <- Tables.NutrientAmount.result
    } yield {
      val byNutrientId   = allNutrientNames.map(n => n.nutrientNameId -> n).toMap
      val byNutrientCode = allNutrientNames.map(n => n.nutrientCode -> n).toMap

      allNutrientAmounts
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
  }

  val allConversionFactors: Map[(FoodId, MeasureId), BigDecimal] = compute {
    Tables.ConversionFactor.result
      .map {
        _.map(row =>
          (row.foodId.transformInto[FoodId], row.measureId.transformInto[MeasureId]) -> row.conversionFactorValue
        ).toMap
      }
  }

  val allNutrients: Map[NutrientCode, Nutrient] = compute {
    Tables.NutrientName.result
      .map {
        _.map { nutrientName =>
          val nutrient = nutrientName.transformInto[Nutrient]
          nutrient.code -> nutrient
        }.toMap
      }
  }

  private def compute[A](action: DBIO[A]): A =
    Await.result(db.run(action), ConstantsConfiguration.default.timeoutInSeconds.seconds)

}
