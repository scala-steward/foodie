package services.duplication.recipe

import db.{ IngredientId, RecipeId, UserId }
import errors.ServerError
import services.complex.ingredient.ComplexIngredient
import services.recipe.{ Ingredient, Recipe }
import slick.dbio.DBIO
import utils.date.SimpleDate

import scala.concurrent.{ ExecutionContext, Future }

trait Duplication {

  def duplicate(
      userId: UserId,
      id: RecipeId,
      simpleDate: SimpleDate
  ): Future[ServerError.Or[Recipe]]

}

object Duplication {

  case class DuplicatedIngredient(
      ingredient: Ingredient,
      newId: IngredientId
  )

  trait Companion {

    def duplicateRecipe(
        userId: UserId,
        id: RecipeId,
        newId: RecipeId,
        timestamp: SimpleDate
    )(implicit ec: ExecutionContext): DBIO[Recipe]

    def duplicateIngredients(
        newRecipeId: RecipeId,
        ingredients: Seq[DuplicatedIngredient]
    )(implicit ec: ExecutionContext): DBIO[Seq[Ingredient]]

    def duplicateComplexIngredients(
        newRecipeId: RecipeId,
        complexIngredients: Seq[ComplexIngredient]
    )(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]]

  }

}
