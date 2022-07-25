package services.nutrient

import cats.Applicative
import cats.data.OptionT
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.{ FoodId, MeasureId, NutrientId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import cats.syntax.traverse._
import cats.syntax.contravariantSemigroupal._
import cats.instances.list._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait NutrientService {

  def nutrientsOf(
      foodId: FoodId,
      measureId: MeasureId,
      amount: BigDecimal
  ): Future[NutrientMap]

}

object NutrientService {

  trait Companion {

    def nutrientOf(
        foodId: FoodId,
        measureId: MeasureId,
        amount: BigDecimal
    )(implicit ec: ExecutionContext): DBIO[NutrientMap]

    def conversionFactor(
        foodId: FoodId,
        measureId: MeasureId
    )(implicit ec: ExecutionContext): DBIO[Tables.ConversionFactorRow]

  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit ec: ExecutionContext)
      extends NutrientService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def nutrientsOf(foodId: FoodId, measureId: MeasureId, amount: BigDecimal): Future[NutrientMap] =
      db.run(companion.nutrientOf(foodId, measureId, amount))

  }

  object Live extends Companion {

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
      )
        .getOrElseF(DBIO.failed(DBError.ConversionFactorNotFound))

    def getNutrient(
        nutrientId: NutrientId
    ): DBIO[Option[Nutrient]] = ???

    def nutrientBaseOf(
        foodId: FoodId
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] =
      for {
        nutrientAmounts <- Tables.NutrientAmount.filter(_.foodId === foodId.transformInto[Int]).result
        pairs <-
          nutrientAmounts
            .traverse(n =>
              (
                getNutrient(n.nutrientId.transformInto[NutrientId]),
                Applicative[DBIO].pure(n.nutrientValue)
              ).mapN((n, a) => n.map(_ -> a))
            )
      } yield NutrientMap(
        pairs.flatten.toMap
      )

    override def nutrientOf(
        foodId: FoodId,
        measureId: MeasureId,
        amount: BigDecimal
    )(implicit
        ec: ExecutionContext
    ): DBIO[NutrientMap] = ???

  }

}
