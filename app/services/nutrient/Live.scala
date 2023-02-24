package services.nutrient

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import db.{ FoodId, MeasureId }
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.recipe.{ AmountUnit, Ingredient }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.implicits._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import javax.inject.Inject
import scala.concurrent.duration.Duration
import scala.concurrent.{ Await, ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: NutrientService.Companion
)(implicit ec: ExecutionContext)
    extends NutrientService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all: Future[Seq[Nutrient]] =
    db.run(companion.all)

}

object Live {

  class Companion @Inject() (override protected val dbConfigProvider: DatabaseConfigProvider)
      extends NutrientService.Companion
      with HasDatabaseConfigProvider[PostgresProfile] {

    // TODO: Remove print statements

    // TODO: Handle injection better
    private val allNutrientMaps: Map[FoodId, NutrientMap] = {
      import scala.concurrent.ExecutionContext.Implicits.global
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

      val finished = Await.result(future, Duration.Inf)
      val end      = System.currentTimeMillis()
      pprint.pprintln(s"Computing all nutrient maps took ${end - start}ms")
      finished
    }

    override def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit
        ec: ExecutionContext
    ): DBIO[Tables.ConversionFactorRow] =
      OptionT(
        Tables.ConversionFactor
          .filter(cf =>
            cf.foodId === foodId.transformInto[Int] &&
              cf.measureId === measureId.transformInto[Int]
          )
          .result
          .headOption: DBIO[Option[Tables.ConversionFactorRow]]
      ).orElse {
        val specialized = hundredGrams(foodId)
        OptionT.when(measureId.transformInto[Int] == specialized.measureId)(specialized)
      }.getOrElseF(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound))

    override def nutrientsOfFood(
        foodId: FoodId,
        measureId: Option[MeasureId],
        factor: BigDecimal
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      for {
        nutrientBase <- nutrientBaseOf(foodId)
        conversionFactor <-
          measureId
            .fold(DBIO.successful(BigDecimal(1)): DBIO[BigDecimal])(
              conversionFactor(foodId, _).map(_.conversionFactorValue)
            )
      } yield factor *: conversionFactor *: nutrientBase

    private def nutrientsOfIngredient(ingredient: Ingredient)(implicit ec: ExecutionContext): DBIO[NutrientMap] =
      nutrientsOfFood(
        foodId = ingredient.foodId,
        measureId = ingredient.amountUnit.measureId,
        factor = ingredient.amountUnit.factor
      )

    override def nutrientsOfIngredients(ingredients: Seq[Ingredient])(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      ingredients
        .traverse(nutrientsOfIngredient)
        .map(_.qsum)

    override def all(implicit ec: ExecutionContext): DBIO[Seq[Nutrient]] =
      Tables.NutrientName.result
        .map(_.map(_.transformInto[Nutrient]))

    private def nutrientBaseOf(
        foodId: FoodId
    ): DBIO[NutrientMap] =
      DBIO.successful(allNutrientMaps.getOrElse(foodId, Map.empty))

    private def hundredGrams(foodId: Int): Tables.ConversionFactorRow =
      Tables.ConversionFactorRow(
        foodId = foodId,
        measureId = AmountUnit.hundredGrams,
        conversionFactorValue = BigDecimal(1),
        convFactorDateOfEntry = java.sql.Date.valueOf("2022-11-01")
      )

  }

}
