package services.complex.food

import db.RecipeId
import org.scalacheck.Gen
import services.GenUtils

object Gens {

  sealed trait VolumeAmountOption

  object VolumeAmountOption {
    case object NoVolume extends VolumeAmountOption

    case object OptionalVolume extends VolumeAmountOption

    case object DefinedVolume extends VolumeAmountOption
  }

  def complexFood(recipeId: RecipeId, volumeAmountOption: VolumeAmountOption): Gen[ComplexFoodIncoming] =
    for {
      amountGrams <- GenUtils.smallBigDecimalGen
      amountMilliLitres <-
        volumeAmountOption match {
          case VolumeAmountOption.NoVolume       => Gen.const(None)
          case VolumeAmountOption.OptionalVolume => Gen.option(GenUtils.smallBigDecimalGen)
          case VolumeAmountOption.DefinedVolume  => GenUtils.smallBigDecimalGen.map(Some(_))
        }
    } yield ComplexFoodIncoming(
      recipeId = recipeId,
      amountGrams = amountGrams,
      amountMilliLitres = amountMilliLitres
    )

}
