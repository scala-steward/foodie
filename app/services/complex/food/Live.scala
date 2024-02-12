package services.complex.food

import cats.data.OptionT
import db.daos.complexFood.ComplexFoodKey
import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.Transactionally.syntax._
import services.complex.ingredient.ScalingMode
import services.recipe.RecipeService
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
    db.runTransactionally(companion.all(userId))

  override def get(userId: UserId, recipeId: RecipeId): Future[Option[ComplexFood]] =
    db.runTransactionally(companion.get(userId, recipeId))

  override def create(
      userId: UserId,
      complexFood: ComplexFoodCreation
  ): Future[ServerError.Or[ComplexFood]] =
    db.runTransactionally(companion.create(userId, complexFood))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ComplexFood.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      complexFoodId: ComplexFoodId,
      update: ComplexFoodUpdate
  ): Future[ServerError.Or[ComplexFood]] =
    db.runTransactionally(companion.update(userId, complexFoodId, update))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.ComplexFood.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, recipeId: RecipeId): Future[Boolean] =
    db.runTransactionally(companion.delete(userId, recipeId))
      .recover { case _ =>
        false
      }

}

object Live {

  class Companion @Inject() (
      recipeService: RecipeService.Companion,
      dao: db.daos.complexFood.DAO,
      complexIngredientDao: db.daos.complexIngredient.DAO
  ) extends ComplexFoodService.Companion {

    override def all(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexFood]] =
      for {
        recipes <- recipeService.allRecipes(userId)
        complex <- dao.allOf(userId, recipes.map(_.id))
      } yield {
        val recipeMap = recipes.map(r => r.id.transformInto[UUID] -> r).toMap
        complex.map { complexFood =>
          ComplexFood.TransformableFromDB(complexFood, recipeMap(complexFood.recipeId)).transformInto[ComplexFood]
        }
      }

    override def get(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[ComplexFood]] = {
      val transformer = for {
        recipe         <- OptionT(recipeService.getRecipe(userId, recipeId))
        complexFoodRow <- OptionT(dao.find(ComplexFoodKey(userId, recipeId)))
      } yield ComplexFood.TransformableFromDB(complexFoodRow, recipe).transformInto[ComplexFood]

      transformer.value
    }

    override def getAll(userId: UserId, recipeIds: Seq[RecipeId])(implicit
        ec: ExecutionContext
    ): DBIO[Seq[ComplexFood]] =
      for {
        recipes         <- recipeService.getRecipes(userId, recipeIds)
        complexFoodRows <- dao.allOf(userId, recipeIds)
      } yield {
        val complexFoodMap = complexFoodRows.map(complexFood => complexFood.recipeId -> complexFood).toMap

        recipes.flatMap { recipe =>
          complexFoodMap
            .get(recipe.id.transformInto[UUID])
            .map(complexFoodRow => ComplexFood.TransformableFromDB(complexFoodRow, recipe).transformInto[ComplexFood])
        }
      }

    override def create(userId: UserId, complexFood: ComplexFoodCreation)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val complexFoodRow =
        ComplexFoodCreation.TransformableToDB(userId, complexFood).transformInto[Tables.ComplexFoodRow]
      for {
        inserted <- dao.insert(complexFoodRow)
        recipe <- OptionT(recipeService.getRecipe(userId, complexFood.recipeId))
          .getOrElseF(DBIO.failed(DBError.Complex.Food.RecipeNotFound))
      } yield ComplexFood.TransformableFromDB(inserted, recipe).transformInto[ComplexFood]
    }

    override def update(
        userId: UserId,
        complexFoodId: ComplexFoodId,
        update: ComplexFoodUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[ComplexFood] = {
      val findAction =
        OptionT(get(userId, complexFoodId))
          .getOrElseF(DBIO.failed(DBError.Complex.Food.NotFound))
      for {
        complexFood <- findAction
        referencing <- complexIngredientDao.findReferencing(complexFoodId)
        _ <-
          if (breaksVolumeReference(referencing, update.amountMilliLitres))
            DBIO.failed(DBError.Complex.Food.VolumeReferenceExists)
          else DBIO.successful(())
        updated = ComplexFoodUpdate.update(complexFood, update)
        _           <- dao.update(ComplexFood.TransformableToDB(userId, updated).transformInto[Tables.ComplexFoodRow])
        updatedFood <- findAction
      } yield updatedFood
    }

    override def delete(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      dao
        .delete(ComplexFoodKey(userId, recipeId))
        .map(_ > 0)

    private def breaksVolumeReference(
        referencing: Seq[Tables.ComplexIngredientRow],
        volumeAmount: Option[BigDecimal]
    ): Boolean =
      referencing.exists(_.scalingMode == ScalingMode.Volume.entryName) && volumeAmount.isEmpty

  }

}
