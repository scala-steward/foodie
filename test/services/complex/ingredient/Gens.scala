package services.complex.ingredient

import cats.syntax.traverse._
import org.scalacheck.Gen
import services.GenUtils
import services.GenUtils.implicits._
import services.complex.food.{ ComplexFood, ComplexFoodCreation }

import scala.util.chaining._

object Gens {

  def complexIngredientsGen(complexFoods: Seq[ComplexFood]): Gen[List[ComplexIngredient]] =
    for {
      subset <- GenUtils.subset(complexFoods)
      scalingModes <- subset.traverse(
        _.amountMilliLitres
          .pipe(scalingModesByVolumeAmount)
          .pipe(Gen.oneOf(_))
      )
      factors <- Gen.listOfN(subset.size, GenUtils.smallBigDecimalGen)
    } yield subset.zip(factors).zip(scalingModes).map { case ((complexFood, factor), scalingMode) =>
      ComplexIngredient(
        complexFoodId = complexFood.recipeId,
        factor = factor,
        scalingMode = scalingMode
      )
    }

  def complexIngredientGen(complexFoods: Seq[ComplexFood]): Gen[ComplexIngredient] =
    for {
      complexFood <- Gen.oneOf(complexFoods)
      factor      <- GenUtils.smallBigDecimalGen
      scalingMode <- Gen.oneOf(scalingModesByVolumeAmount(complexFood.amountMilliLitres))
    } yield ComplexIngredient(
      complexFoodId = complexFood.recipeId,
      factor = factor,
      scalingMode = scalingMode
    )

  def complexIngredientCreationGen(complexFoods: Seq[ComplexFood]): Gen[ComplexIngredientCreation] =
    for {
      complexFood <- Gen.oneOf(complexFoods)
      factor      <- GenUtils.smallBigDecimalGen
      scalingMode <- Gen.oneOf(scalingModesByVolumeAmount(complexFood.amountMilliLitres))
    } yield ComplexIngredientCreation(
      complexFoodId = complexFood.recipeId,
      factor = factor,
      scalingMode = scalingMode
    )

  def complexIngredientUpdateGen(amountMillilitres: Option[BigDecimal]): Gen[ComplexIngredientUpdate] =
    for {
      factor      <- GenUtils.smallBigDecimalGen
      scalingMode <- Gen.oneOf(scalingModesByVolumeAmount(amountMillilitres))
    } yield ComplexIngredientUpdate(
      factor = factor,
      scalingMode = scalingMode
    )

  private def scalingModesByVolumeAmount(
      volumeAmount: Option[BigDecimal]
  ): Seq[ScalingMode] =
    volumeAmount.fold(Seq(ScalingMode.Recipe, ScalingMode.Weight): Seq[ScalingMode])(_ => ScalingMode.values)

}
