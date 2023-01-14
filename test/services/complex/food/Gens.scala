package services.complex.food

import cats.data.NonEmptyList
import db.RecipeId
import org.scalacheck.Gen
import services.GenUtils

object Gens {

  def complexFood(recipeId: RecipeId): Gen[ComplexFoodIncoming] =
    for {
      amount   <- GenUtils.smallBigDecimalGen
      unit     <- Gen.oneOf(ComplexFoodUnit.values)
    } yield ComplexFoodIncoming(
      recipeId = recipeId,
      amount = amount,
      unit = unit
    )

}
