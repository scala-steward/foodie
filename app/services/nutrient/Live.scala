package services.nutrient

import cats.syntax.traverse._
import db.generated.Tables
import db.{ FoodId, MeasureId }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.recipe.{ AmountUnit, Ingredient }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import spire.implicits._
import utils.TransformerUtils.Implicits._

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }
import scala.util.chaining.scalaUtilChainingOps

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: NutrientService.Companion
) extends NutrientService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all: Future[Seq[Nutrient]] =
    db.run(companion.all)

}

object Live {

  class Companion @Inject() (fullTableConstants: FullTableConstants) extends NutrientService.Companion {

    override def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit
        ec: ExecutionContext
    ): DBIO[BigDecimal] =
      conversionFactorNoEffect(foodId, measureId)
        .fold(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound): DBIO[BigDecimal])(DBIO.successful)

    private def conversionFactorNoEffect(
        foodId: FoodId,
        measureId: MeasureId
    ): Option[BigDecimal] = fullTableConstants.allConversionFactors
      .get((foodId, measureId))
      .orElse {
        val specialized = hundredGrams(foodId)
        Option.when(measureId.transformInto[Int] == specialized.measureId)(specialized.conversionFactorValue)
      }

    override def conversionFactors(
        conversionFactorKeys: Seq[NutrientService.ConversionFactorKey]
    )(implicit ec: ExecutionContext): DBIO[Map[NutrientService.ConversionFactorKey, BigDecimal]] = {
      val (errors, factors) = conversionFactorKeys.partitionMap { key =>
        fullTableConstants.allConversionFactors
          .get((key.foodId, key.measureId))
          .map(key -> _)
          .toRight(())
      }
      // TODO: Do we really want to fail entirely?
      if (errors.isEmpty)
        DBIO.successful(factors.toMap)
      else DBIO.failed(DBError.Nutrient.ConversionFactorNotFound)
    }

    override def nutrientsOfFood(
        foodId: FoodId,
        measureId: Option[MeasureId],
        factor: BigDecimal
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      for {
        conversionFactor <-
          measureId
            .fold(DBIO.successful(BigDecimal(1)): DBIO[BigDecimal])(
              conversionFactor(foodId, _)
            )
      } yield factor *: conversionFactor *: nutrientBaseOf(foodId)

    private def nutrientsOfFoodNoEffect(
        foodId: FoodId,
        measureId: Option[MeasureId],
        factor: BigDecimal
    ): Option[NutrientMap] =
      measureId
        .fold(Option(BigDecimal(1)))(conversionFactorNoEffect(foodId, _))
        .map { conversionFactor =>
          factor *: conversionFactor *: nutrientBaseOf(foodId)
        }

    // TODO: Check usage
    private def conversionFactorsOf(conversionFactorKeys: Seq[NutrientService.ConversionFactorKey]) =
      conversionFactorKeys.flatMap { key =>
        fullTableConstants.allConversionFactors
          .get((key.foodId, key.measureId))
          .map(key -> _)
      }.toMap

    override def nutrientsOfIngredients(ingredients: Seq[Ingredient])(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      ingredients
        .traverse { ingredient =>
          nutrientsOfFoodNoEffect(
            foodId = ingredient.foodId,
            measureId = ingredient.amountUnit.measureId,
            factor = ingredient.amountUnit.factor
          )
        }
        .fold(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound))(
          _.pipe(_.qsum)
            .pipe(DBIO.successful(_))
        )

    override val all: DBIO[Seq[Nutrient]] =
      DBIO.successful(fullTableConstants.allNutrients)

    private def nutrientBaseOf(
        foodId: FoodId
    ): NutrientMap =
      fullTableConstants.allNutrientMaps
        .getOrElse(foodId, Map.empty)

    private def hundredGrams(foodId: Int): Tables.ConversionFactorRow =
      Tables.ConversionFactorRow(
        foodId = foodId,
        measureId = AmountUnit.hundredGrams,
        conversionFactorValue = BigDecimal(1),
        convFactorDateOfEntry = java.sql.Date.valueOf("2022-11-01")
      )

  }

}
