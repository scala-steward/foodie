package services.meal

import cats.data.NonEmptyList
import db.{ MealEntryId, MealId, RecipeId }
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services._
import spire.math.Natural
import utils.TransformerUtils.Implicits._

object Gens {

  def mealCreationGen(earliest: Int = -100000, latest: Int = 100000): Gen[MealCreation] =
    for {
      name <- Gen.option(GenUtils.nonEmptyAsciiString)
      date <- GenUtils.simpleDateGen(earliest, latest)
    } yield MealCreation(
      date = date,
      name = name
    )

  def mealGen(earliest: Int = -100000, latest: Int = 100000): Gen[Meal] = {
    for {
      id           <- Gen.uuid.map(_.transformInto[MealId])
      mealCreation <- mealCreationGen(earliest, latest)
    } yield MealCreation.create(id, mealCreation)
  }

  def mealUpdateGen(mealId: MealId, earliest: Int = -100000, latest: Int = 100000): Gen[MealUpdate] =
    for {
      name <- Gen.option(GenUtils.nonEmptyAsciiString)
      date <- GenUtils.simpleDateGen(earliest, latest)
    } yield MealUpdate(
      id = mealId,
      date = date,
      name = name
    )

  def mealEntryGen(recipeIds: NonEmptyList[RecipeId]): Gen[MealEntry] =
    for {
      mealEntryId      <- Gen.uuid.map(_.transformInto[MealEntryId])
      recipeId         <- Gen.oneOf(recipeIds.toList)
      numberOfServings <- GenUtils.smallBigDecimalGen
    } yield MealEntry(
      id = mealEntryId,
      recipeId = recipeId,
      numberOfServings = numberOfServings
    )

  def mealEntryUpdateGen(mealEntryId: MealEntryId, recipeIds: NonEmptyList[RecipeId]): Gen[MealEntryUpdate] =
    for {
      recipeId         <- Gen.oneOf(recipeIds.toList)
      numberOfServings <- GenUtils.smallBigDecimalGen
    } yield MealEntryUpdate(
      id = mealEntryId,
      recipeId = recipeId,
      numberOfServings = numberOfServings
    )

  def fullMealGen(
      recipeIds: NonEmptyList[RecipeId],
      earliest: Int = -100000,
      latest: Int = 100000
  ): Gen[FullMeal] =
    for {
      mealEntries <- GenUtils.nonEmptyListOfAtMost(Natural(10), mealEntryGen(recipeIds))
      meal        <- mealGen(earliest, latest)
    } yield FullMeal(
      meal = meal,
      mealEntries = mealEntries.toList
    )

}
