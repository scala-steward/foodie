package services.complex.food

import db.RecipeId
import org.scalacheck.Gen
import services.GenUtils

object Gens {

  def complexFood(recipeId: RecipeId): Gen[ComplexFoodIncoming] =
    for {
      amountGrams       <- GenUtils.smallBigDecimalGen
      amountMilliLitres <- Gen.option(GenUtils.smallBigDecimalGen)
    } yield ComplexFoodIncoming(
      recipeId = recipeId,
      amountGrams = amountGrams,
      amountMilliLitres = amountMilliLitres
    )

}
