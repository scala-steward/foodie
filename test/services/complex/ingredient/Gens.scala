package services.complex.ingredient

import cats.syntax.traverse._
import db.RecipeId
import org.scalacheck.Gen
import services.GenUtils
import services.GenUtils.implicits._
import services.complex.food.{ ComplexFood, ComplexFoodIncoming }

import scala.util.chaining._

object Gens {

  def complexIngredientsGen(recipeId: RecipeId, complexFoods: Seq[ComplexFoodIncoming]): Gen[List[ComplexIngredient]] =
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
        recipeId = recipeId,
        complexFoodId = complexFood.recipeId,
        factor = factor,
        scalingMode = scalingMode
      )
    }

  def complexIngredientGen(recipeId: RecipeId, complexFoods: Seq[ComplexFoodIncoming]): Gen[ComplexIngredient] =
    for {
      complexFood <- Gen.oneOf(complexFoods)
      factor      <- GenUtils.smallBigDecimalGen
      scalingMode <- Gen.oneOf(scalingModesByVolumeAmount(complexFood.amountMilliLitres))
    } yield ComplexIngredient(
      recipeId = recipeId,
      complexFoodId = complexFood.recipeId,
      factor = factor,
      scalingMode = scalingMode
    )

  private def scalingModesByVolumeAmount(
      volumeAmount: Option[BigDecimal]
  ): Seq[ScalingMode] =
    volumeAmount.fold(Seq(ScalingMode.Recipe, ScalingMode.Weight): Seq[ScalingMode])(_ => ScalingMode.values)

}
