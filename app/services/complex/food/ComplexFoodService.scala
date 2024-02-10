package services.complex.food

import db.{ ComplexFoodId, RecipeId, UserId }
import errors.ServerError
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait ComplexFoodService {

  def all(userId: UserId): Future[Seq[ComplexFood]]

  def get(userId: UserId, recipeId: RecipeId): Future[Option[ComplexFood]]

  def create(
      userId: UserId,
      complexFood: ComplexFoodIncoming
  ): Future[ServerError.Or[ComplexFood]]

  def update(
      userId: UserId,
      complexFoodId: ComplexFoodId,
      update: ComplexFoodUpdate
  ): Future[ServerError.Or[ComplexFood]]

  def delete(userId: UserId, recipeId: RecipeId): Future[Boolean]

}

object ComplexFoodService {

  trait Companion {
    def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]]

    def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]]

    def getAll(userId: UserId, recipeIds: Seq[RecipeId])(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]]

    def create(
        userId: UserId,
        complexFood: ComplexFoodIncoming
    )(implicit ec: ExecutionContext): DBIO[ComplexFood]

    def update(
        userId: UserId,
        complexFoodId: ComplexFoodId,
        update: ComplexFoodUpdate
    )(implicit ec: ExecutionContext): DBIO[ComplexFood]

    def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean]
  }

}
