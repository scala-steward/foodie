package services.complex.ingredient

import db.{ ComplexFoodId, RecipeId, UserId }
import errors.ServerError
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait ComplexIngredientService {

  def all(userId: UserId, recipeId: RecipeId): Future[Seq[ComplexIngredient]]

  def create(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]]

  def update(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]]

  def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId): Future[Boolean]

}

object ComplexIngredientService {

  trait Companion {
    def all(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]]

    def create(
        userId: UserId,
        complexIngredient: ComplexIngredient
    )(implicit ec: ExecutionContext): DBIO[ComplexIngredient]

    def update(
        userId: UserId,
        complexIngredient: ComplexIngredient
    )(implicit ec: ExecutionContext): DBIO[ComplexIngredient]

    def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean]

  }

}
