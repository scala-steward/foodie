package services.complex.food

import db.RecipeId
import org.scalacheck.Gen
import services.GenUtils
import services.recipe.Recipe

object Gens {

  sealed trait VolumeAmountOption

  object VolumeAmountOption {
    case object NoVolume extends VolumeAmountOption

    case object OptionalVolume extends VolumeAmountOption

    case object DefinedVolume extends VolumeAmountOption
  }

  def complexFoodCreation(recipeId: RecipeId, volumeAmountOption: VolumeAmountOption): Gen[ComplexFoodCreation] =
    for {
      update <- complexFoodUpdate(volumeAmountOption)
    } yield ComplexFoodCreation(
      recipeId = recipeId,
      amountGrams = update.amountGrams,
      amountMilliLitres = update.amountMilliLitres
    )

  def complexFood(recipe: Recipe, volumeAmountOption: VolumeAmountOption): Gen[ComplexFood] =
    for {
      update <- complexFoodUpdate(volumeAmountOption)
    } yield ComplexFoodCreation.create(
      recipe.name,
      recipe.description,
      ComplexFoodCreation(
        recipeId = recipe.id,
        amountGrams = update.amountGrams,
        amountMilliLitres = update.amountMilliLitres
      )
    )

  def complexFoodUpdate(volumeAmountOption: VolumeAmountOption): Gen[ComplexFoodUpdate] =
    for {
      amountGrams       <- GenUtils.smallBigDecimalGen
      amountMilliLitres <-
        volumeAmountOption match {
          case VolumeAmountOption.NoVolume       => Gen.const(None)
          case VolumeAmountOption.OptionalVolume => Gen.option(GenUtils.smallBigDecimalGen)
          case VolumeAmountOption.DefinedVolume  => GenUtils.smallBigDecimalGen.map(Some(_))
        }
    } yield ComplexFoodUpdate(
      amountGrams = amountGrams,
      amountMilliLitres = amountMilliLitres
    )

}
