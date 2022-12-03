package services.meal

import cats.data.NonEmptyList
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services._
import spire.math.Natural
import utils.TransformerUtils.Implicits._

object Gens {

  def mealEntryGen(recipeIds: NonEmptyList[RecipeId]): Gen[MealEntryParameters] =
    for {
      mealEntryId      <- Gen.uuid.map(_.transformInto[MealEntryId])
      recipeId         <- Gen.oneOf(recipeIds.toList)
      numberOfServings <- GenUtils.smallBigDecimalGen
    } yield MealEntryParameters(
      mealEntryId = mealEntryId,
      mealEntryPreCreation = MealEntryPreCreation(
        recipeId = recipeId,
        numberOfServings = numberOfServings
      )
    )

  def fullMealGen(
      recipeIds: List[RecipeId],
      earliest: Int = -100000,
      latest: Int = 100000
  ): Gen[MealParameters] =
    for {
      mealEntryParameters <-
        NonEmptyList
          .fromList(recipeIds)
          .fold(Gen.const(List.empty[MealEntryParameters]))(nel =>
            GenUtils.listOfAtMost(Natural(10), mealEntryGen(nel))
          )
      mealCreation <- mealCreationGen(earliest, latest)
    } yield MealParameters(
      mealCreation = mealCreation,
      mealEntryParameters = mealEntryParameters
    )

  def mealCreationGen(earliest: Int = -100000, latest: Int = 100000): Gen[MealCreation] =
    for {
      name <- Gen.option(GenUtils.nonEmptyAsciiString)
      date <- GenUtils.simpleDateGen(earliest, latest)
    } yield MealCreation(
      date = date,
      name = name
    )

}
