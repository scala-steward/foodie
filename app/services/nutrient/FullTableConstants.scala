package services.nutrient

import db.{ FoodId, MeasureId }
import db.generated.Tables
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._
import io.scalaland.chimney.dsl._

import javax.inject.{ Inject, Singleton }
import scala.concurrent.duration.Duration
import scala.concurrent.{ Await, ExecutionContext }

@Singleton
class FullTableConstants @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider
)(implicit executionContext: ExecutionContext)
    extends HasDatabaseConfigProvider[PostgresProfile] {

  // TODO: Remove print statements

  val allNutrientMaps: Map[FoodId, NutrientMap] = {
    pprint.pprintln("Start computing all nutrient maps")
    val start = System.currentTimeMillis()
    val action = for {
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

    val future = db
      .run(action)

    // TODO: Set sensible timeout
    val finished = Await.result(future, Duration.Inf)
    val end      = System.currentTimeMillis()
    pprint.pprintln(s"Computing all nutrient maps took ${end - start}ms")
    finished
  }

  val allConversionFactors: Map[(FoodId, MeasureId), BigDecimal] = {
    val action = Tables.ConversionFactor.result
      .map {
        _.map(row =>
          (row.foodId.transformInto[FoodId], row.measureId.transformInto[MeasureId]) -> row.conversionFactorValue
        ).toMap
      }
    val future = db
      .run(action)
    // TODO: Set sensible timeout
    Await.result(future, Duration.Inf)
  }

  val allNutrients: Seq[Nutrient] = {
    val action = Tables.NutrientName.result
      .map(_.map(_.transformInto[Nutrient]))

    val future = db
      .run(action)
    // TODO: Set sensible timeout
    Await.result(future, Duration.Inf)
  }

}
