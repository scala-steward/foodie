package services.complex.food

import cats.data.OptionT
import db.generated.Tables
import db.{ RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.recipe.{ Recipe, RecipeService }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: ComplexFoodService.Companion
)(implicit ec: ExecutionContext)
    extends ComplexFoodService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all(userId: UserId): Future[Seq[ComplexFood]] =
    db.run(companion.all(userId))

  override def get(userId: UserId, recipeId: RecipeId): Future[Option[ComplexFood]] =
    db.run(companion.get(userId, recipeId))

  override def create(
      userId: UserId,
      complexFood: ComplexFoodIncoming
  ): Future[ServerError.Or[ComplexFood]] =
    db.run(companion.create(userId, complexFood))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.ComplexFood.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      complexFood: ComplexFoodIncoming
  ): Future[ServerError.Or[ComplexFood]] =
    db.run(companion.update(userId, complexFood))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.ComplexFood.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, recipeId: RecipeId): Future[Boolean] =
    db.run(companion.delete(userId, recipeId))

}

object Live {

  class Companion @Inject() (
      recipeService: RecipeService.Companion
  ) extends ComplexFoodService.Companion {

    override def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]] =
      for {
        recipes <- recipeService.allRecipes(userId)
        complex <- Tables.ComplexFood.filter(_.recipeId.inSetBind(recipes.map(_.id))).result
      } yield {
        val recipeMap = recipes.map(r => r.id.transformInto[UUID] -> r).toMap
        complex.map { complexFood =>
          (complexFood, recipeMap(complexFood.recipeId)).transformInto[ComplexFood]
        }
      }

    override def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]] = {
      val transformer = for {
        recipe <- OptionT(recipeService.getRecipe(userId, recipeId))
        complexFoodRow <- OptionT(
          Tables.ComplexFood
            .filter(_.recipeId === recipeId.transformInto[UUID])
            .result
            .headOption: DBIO[Option[Tables.ComplexFoodRow]]
        )
      } yield (complexFoodRow, recipe).transformInto[ComplexFood]

      transformer.value
    }

    override def create(userId: UserId, complexFood: ComplexFoodIncoming)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val complexFoodRow = complexFood.transformInto[Tables.ComplexFoodRow]
      ifRecipeExists(userId, complexFood.recipeId) { recipe =>
        (Tables.ComplexFood.returning(Tables.ComplexFood) += complexFoodRow)
          .map(complexFood => (complexFood, recipe).transformInto[ComplexFood])
      }
    }

    override def update(userId: UserId, complexFood: ComplexFoodIncoming)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val findAction =
        OptionT(get(userId, complexFood.recipeId))
          .getOrElseF(DBIO.failed(DBError.Complex.Food.NotFound))
      for {
        _ <- findAction
        _ <- complexFoodQuery(complexFood.recipeId)
          .update(complexFood.transformInto[Tables.ComplexFoodRow])
        updatedFood <- findAction
      } yield updatedFood
    }

    override def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      complexFoodQuery(recipeId).delete
        .map(_ > 0)

    private def ifRecipeExists[A](
        userId: UserId,
        recipeId: RecipeId
    )(action: Recipe => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      recipeService
        .getRecipe(userId, recipeId)
        .flatMap(maybeRecipe => maybeRecipe.fold(DBIO.failed(DBError.Complex.Food.RecipeNotFound): DBIO[A])(action))

    private def complexFoodQuery(
        recipeId: RecipeId
    ): Query[Tables.ComplexFood, Tables.ComplexFoodRow, Seq] =
      Tables.ComplexFood.filter(_.recipeId === recipeId.transformInto[UUID])

  }

}
