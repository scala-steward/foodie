package services

import cats.data.NonEmptyList
import db.generated.Tables
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import security.Hash
import services.nutrient.{ Nutrient, NutrientService }
import services.recipe._
import services.user.User
import slick.jdbc.PostgresProfile.api._
import spire.math.Natural
import utils.TransformerUtils.Implicits._
import utils.date.{ Date, SimpleDate, Time }

import java.time.LocalDate

object GenUtils {

  private val recipeService   = TestUtil.injector.instanceOf[RecipeService]
  private val nutrientService = TestUtil.injector.instanceOf[NutrientService]

  val nonEmptyAsciiString: Gen[String] =
    Gen
      .nonEmptyListOf(Gen.asciiPrintableChar)
      .map(_.mkString)

  val userWithFixedPassword: Gen[User] = for {
    id          <- Gen.uuid.map(_.transformInto[UserId])
    nickname    <- nonEmptyAsciiString
    displayName <- Gen.option(nonEmptyAsciiString)
    email       <- nonEmptyAsciiString
    salt        <- Gen.listOfN(40, Gen.alphaNumChar).map(_.mkString)
  } yield User(
    id = id,
    nickname = nickname,
    displayName = displayName,
    email = email,
    salt = salt,
    hash = Hash.fromPassword("password", salt, Hash.defaultIterations)
  )

  def optionalOneOf[A](seq: Seq[A]): Gen[Option[A]] =
    if (seq.isEmpty)
      Gen.const(None)
    else Gen.option(Gen.oneOf(seq))

  def listOfAtMost[A](n: Natural, gen: Gen[A]): Gen[List[A]] =
    Gen
      .choose(0, n.intValue)
      .flatMap(Gen.listOfN(_, gen))

  def nonEmptyListOfAtMost[A](n: Natural, gen: Gen[A]): Gen[NonEmptyList[A]] =
    Gen
      .choose(1, n.intValue.max(1))
      .flatMap(Gen.listOfN(_, gen))
      .map(NonEmptyList.fromListUnsafe)

  val timeGen: Gen[Time] = for {
    hour   <- Gen.choose(0, 23)
    minute <- Gen.choose(0, 59)
  } yield Time(
    hour = hour,
    minute = minute
  )

  def dateGen(earliest: Int = -100000, latest: Int = 100000): Gen[Date] =
    Gen
      .choose(earliest, latest)
      .map(c => LocalDate.ofEpochDay(c).transformInto[Date])

  def simpleDateGen(earliest: Int = -100000, latest: Int = 100000): Gen[SimpleDate] =
    for {
      date <- dateGen(earliest, latest)
      time <- Gen.option(timeGen)
    } yield SimpleDate(
      date = date,
      time = time
    )

  val allFoods: Seq[Food] = DBTestUtil
    .await(recipeService.allFoods)
    .map(food =>
      food.copy(
        measures = food.measures
          .filter(measure => measure.id != AmountUnit.hundredGrams)
      )
    )

  val allNutrients: Seq[Nutrient] = DBTestUtil.await(nutrientService.all)

  val allConversionFactors: Map[(FoodId, MeasureId), BigDecimal] =
    DBTestUtil
      .await(DBTestUtil.dbRun(Tables.ConversionFactor.result))
      .map { row =>
        (row.foodId.transformInto[FoodId], row.measureId.transformInto[MeasureId]) -> row.conversionFactorValue
      }
      .toMap

  lazy val foodGen: Gen[Food] =
    Gen.oneOf(allFoods)

  val smallBigDecimalGen: Gen[BigDecimal] = Gen.choose(BigDecimal(0.001), BigDecimal(1000))

}
