package services.nutrient

import cats.data.OptionT
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
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

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
      OptionT
        .fromOption[DBIO](
          fullTableConstants.allConversionFactors
            .get((foodId, measureId))
        )
        .orElse {
          val specialized = hundredGrams(foodId)
          OptionT.when(measureId.transformInto[Int] == specialized.measureId)(specialized.conversionFactorValue)
        }
        .getOrElseF(DBIO.failed(DBError.Nutrient.ConversionFactorNotFound))

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
