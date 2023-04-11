package services.rescale

import db.{ RecipeId, UserId }
import errors.ServerError
import services.recipe.Recipe
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait RescaleService {

  def rescale(
      userId: UserId,
      recipeId: RecipeId
  ): Future[ServerError.Or[Recipe]]

}

object RescaleService {

  trait Companion {

    def rescale(
        userId: UserId,
        recipeId: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Recipe]

  }

}
