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
      .recover { case error =>
        Left(ErrorContext.ComplexFood.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      complexFood: ComplexFoodIncoming
  ): Future[ServerError.Or[ComplexFood]] =
    db.run(companion.update(userId, complexFood))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ComplexFood.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, recipeId: RecipeId): Future[Boolean] =
    db.run(companion.delete(userId, recipeId))
      .recover { case _ =>
        false
      }

}

object Live {

  class Companion @Inject() (
      recipeService: RecipeService.Companion,
      dao: db.daos.complexFood.DAO
  ) extends ComplexFoodService.Companion {

    override def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]] =
      for {
        recipes <- recipeService.allRecipes(userId)
        complex <- dao.findByKeys(recipes.map(_.id))
      } yield {
        val recipeMap = recipes.map(r => r.id.transformInto[UUID] -> r).toMap
        complex.map { complexFood =>
          (complexFood, recipeMap(complexFood.recipeId)).transformInto[ComplexFood]
        }
      }

    override def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]] = {
      val transformer = for {
        recipe         <- OptionT(recipeService.getRecipe(userId, recipeId))
        complexFoodRow <- OptionT(dao.find(recipeId))
      } yield (complexFoodRow, recipe).transformInto[ComplexFood]

      transformer.value
    }

    override def getAll(userId: UserId, recipeIds: Seq[RecipeId])(implicit
        ec: ExecutionContext
    ): DBIO[Seq[ComplexFood]] =
      for {
        recipes         <- recipeService.getRecipes(userId, recipeIds)
        complexFoodRows <- dao.findByKeys(recipeIds)
      } yield {
        val complexFoodMap = complexFoodRows.map(complexFood => complexFood.recipeId -> complexFood).toMap

        recipes.flatMap { recipe =>
          complexFoodMap
            .get(recipe.id.transformInto[UUID])
            .map(complexFoodRow => (complexFoodRow, recipe).transformInto[ComplexFood])
        }
      }

    override def create(userId: UserId, complexFood: ComplexFoodIncoming)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val complexFoodRow = complexFood.transformInto[Tables.ComplexFoodRow]
      ifRecipeExists(userId, complexFood.recipeId) { recipe =>
        dao
          .insert(complexFoodRow)
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
        _           <- findAction
        _           <- dao.update(complexFood.transformInto[Tables.ComplexFoodRow])
        updatedFood <- findAction
      } yield updatedFood
    }

    override def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      ifRecipeExists(userId, recipeId) { recipe =>
        dao
          .delete(recipe.id)
          .map(_ > 0)
      }

    private def ifRecipeExists[A](
        userId: UserId,
        recipeId: RecipeId
    )(action: Recipe => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      recipeService
        .getRecipe(userId, recipeId)
        .flatMap(maybeRecipe => maybeRecipe.fold(DBIO.failed(DBError.Complex.Food.RecipeNotFound): DBIO[A])(action))

  }

}
