package services.complex.food

import errors.ServerError
import services.{ RecipeId, UserId }
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
      complexFood: ComplexFoodIncoming
  ): Future[ServerError.Or[ComplexFood]]

  def delete(userId: UserId, recipeId: RecipeId): Future[Boolean]

}

object ComplexFoodService {

  trait Companion {
    def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]]

    def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]]

    def create(
        userId: UserId,
        complexFood: ComplexFoodIncoming
    )(implicit ec: ExecutionContext): DBIO[ComplexFood]

    def update(
        userId: UserId,
        complexFood: ComplexFoodIncoming
    )(implicit ec: ExecutionContext): DBIO[ComplexFood]

    def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean]
  }

}
