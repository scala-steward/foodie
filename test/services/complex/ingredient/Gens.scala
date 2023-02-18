package services.complex.ingredient

import db.{ ComplexFoodId, RecipeId }
import org.scalacheck.Gen
import services.GenUtils

object Gens {

  def complexIngredientsGen(recipeId: RecipeId, complexFoodIds: Seq[ComplexFoodId]): Gen[Seq[ComplexIngredient]] =
    for {
      subset  <- GenUtils.subset(complexFoodIds)
      factors <- Gen.listOfN(subset.size, GenUtils.smallBigDecimalGen)
    } yield subset.zip(factors).map { case (complexFoodId, factor) =>
      ComplexIngredient(
        recipeId = recipeId,
        complexFoodId = complexFoodId,
        factor = factor
      )
    }

  def complexIngredientGen(recipeId: RecipeId, complexFoodIds: Seq[ComplexFoodId]): Gen[ComplexIngredient] =
    for {
      complexFoodId <- Gen.oneOf(complexFoodIds)
      factor        <- GenUtils.smallBigDecimalGen
    } yield ComplexIngredient(
      recipeId = recipeId,
      complexFoodId = complexFoodId,
      factor = factor
    )

}
