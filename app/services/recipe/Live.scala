package services.recipe

import cats.Applicative
import cats.data.OptionT
import cats.syntax.traverse._
import db.daos.recipe.RecipeKey
import db.generated.Tables
import db.{ FoodId, IngredientId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
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
    companion: RecipeService.Companion
)(implicit
    executionContext: ExecutionContext
) extends RecipeService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def allFoods: Future[Seq[Food]] = db.run(companion.allFoods)

  override def getFoodInfo(foodId: FoodId): Future[Option[FoodInfo]] = db.run(companion.getFoodInfo(foodId))

  override def allMeasures: Future[Seq[Measure]] = db.run(companion.allMeasures)

  override def allRecipes(userId: UserId): Future[Seq[Recipe]] = db.run(companion.allRecipes(userId))

  override def getRecipe(
      userId: UserId,
      id: RecipeId
  ): Future[Option[Recipe]] =
    db.run(companion.getRecipe(userId, id))

  // TODO: The error can be specialized, because the most likely case is that the user is missing,
  // and thus a foreign key constraint is not met.
  override def createRecipe(
      userId: UserId,
      recipeCreation: RecipeCreation
  ): Future[ServerError.Or[Recipe]] = {
    db.run(companion.createRecipe(userId, UUID.randomUUID().transformInto[RecipeId], recipeCreation))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.Recipe.Creation(error.getMessage).asServerError)
      }
  }

  override def updateRecipe(
      userId: UserId,
      recipeUpdate: RecipeUpdate
  ): Future[ServerError.Or[Recipe]] =
    db.run(companion.updateRecipe(userId, recipeUpdate))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.Recipe.Update(error.getMessage).asServerError)
      }

  override def deleteRecipe(
      userId: UserId,
      id: RecipeId
  ): Future[Boolean] = db.run(companion.deleteRecipe(userId, id))

  override def getIngredients(userId: UserId, recipeId: RecipeId): Future[List[Ingredient]] =
    db.run(companion.getIngredients(userId, recipeId))

  override def addIngredient(
      userId: UserId,
      ingredientCreation: IngredientCreation
  ): Future[ServerError.Or[Ingredient]] =
    db.run(companion.addIngredient(userId, UUID.randomUUID().transformInto[IngredientId], ingredientCreation))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.Recipe.Ingredient.Creation(error.getMessage).asServerError)
      }

  override def updateIngredient(
      userId: UserId,
      ingredientUpdate: IngredientUpdate
  ): Future[ServerError.Or[Ingredient]] =
    db.run(companion.updateIngredient(userId, ingredientUpdate))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.Recipe.Ingredient.Update(error.getMessage).asServerError)
      }

  override def removeIngredient(userId: UserId, ingredientId: IngredientId): Future[Boolean] =
    db.run(companion.removeIngredient(userId, ingredientId))
      .recover { _ =>
        false
      }

}

object Live {

  class Companion @Inject() (
      recipeDao: db.daos.recipe.DAO,
      ingredientDao: db.daos.ingredient.DAO
  ) extends RecipeService.Companion {

    override def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]] =
      for {
        foods <- Tables.FoodName.result
        withMeasure <- foods.traverse { food =>
          Tables.ConversionFactor
            .filter(cf => cf.foodId === food.foodId)
            .map(_.measureId)
            .result
            .flatMap(measureIds =>
              Tables.MeasureName
                .filter(_.measureId.inSetBind(AmountUnit.hundredGrams.transformInto[Int] +: measureIds))
                .result
                .map(ms => food -> ms.toList)
            ): DBIO[(Tables.FoodNameRow, List[Tables.MeasureNameRow])]
        }
      } yield withMeasure.map(_.transformInto[Food])

    override def getFoodInfo(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[FoodInfo]] =
      Tables.FoodName
        .filter(_.foodId === foodId.transformInto[Int])
        .result
        .headOption
        .map(_.map(_.transformInto[FoodInfo]))

    override def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
      Tables.MeasureName.result
        .map(_.map(_.transformInto[Measure]))

    override def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]] =
      recipeDao
        .findBy(_.userId === userId.transformInto[UUID])
        .map(
          _.map(_.transformInto[Recipe])
        )

    override def getRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[Recipe]] =
      OptionT(
        recipeDao.find(RecipeKey(userId, id))
      ).map(_.transformInto[Recipe]).value

    override def createRecipe(
        userId: UserId,
        id: RecipeId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val recipe    = RecipeCreation.create(id, recipeCreation)
      val recipeRow = (recipe, userId).transformInto[Tables.RecipeRow]
      recipeDao
        .insert(recipeRow)
        .map(_.transformInto[Recipe])
    }

    override def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val findAction = OptionT(getRecipe(userId, recipeUpdate.id)).getOrElseF(notFound)
      for {
        recipe <- findAction
        _ <- recipeDao.update(
          (
            RecipeUpdate
              .update(recipe, recipeUpdate),
            userId
          )
            .transformInto[Tables.RecipeRow]
        )(RecipeKey.of)
        updatedRecipe <- findAction
      } yield updatedRecipe
    }

    override def deleteRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      recipeDao
        .delete(RecipeKey(userId, id))
        .map(_ > 0)

    override def getIngredients(
        userId: UserId,
        recipeId: RecipeId
    )(implicit
        ec: ExecutionContext
    ): DBIO[List[Ingredient]] =
      for {
        exists <- recipeDao.exists(RecipeKey(userId, recipeId))
        ingredients <-
          if (exists)
            ingredientDao
              .findBy(_.recipeId === recipeId.transformInto[UUID])
              .map(_.map(_.transformInto[Ingredient]).toList)
          else Applicative[DBIO].pure(List.empty)
      } yield ingredients

    override def addIngredient(
        userId: UserId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val ingredient    = IngredientCreation.create(id, ingredientCreation)
      val ingredientRow = (ingredient, ingredientCreation.recipeId).transformInto[Tables.RecipeIngredientRow]
      ifRecipeExists(userId, ingredientCreation.recipeId) {
        ingredientDao
          .insert(ingredientRow)
          .map(_.transformInto[Ingredient])
      }
    }

    override def updateIngredient(
        userId: UserId,
        ingredientUpdate: IngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val findAction =
        OptionT(ingredientDao.find(ingredientUpdate.id))
          .getOrElseF(DBIO.failed(DBError.Recipe.IngredientNotFound))
      for {
        ingredientRow <- findAction
        _ <- ifRecipeExists(userId, ingredientRow.recipeId.transformInto[RecipeId]) {
          ingredientDao.update(
            (
              IngredientUpdate
                .update(ingredientRow.transformInto[Ingredient], ingredientUpdate),
              ingredientRow.recipeId.transformInto[RecipeId]
            )
              .transformInto[Tables.RecipeIngredientRow]
          )(_.id.transformInto[IngredientId])
        }
        updatedIngredientRow <- findAction
      } yield updatedIngredientRow.transformInto[Ingredient]
    }

    override def removeIngredient(
        userId: UserId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean] = {
      OptionT(
        ingredientDao.find(id)
      ).map(_.recipeId)
        .semiflatMap(recipeId =>
          ifRecipeExists(userId, recipeId.transformInto[RecipeId]) {
            ingredientDao
              .delete(id)
              .map(_ > 0)
          }
        )
        .getOrElse(false)
    }

    private def ifRecipeExists[A](
        userId: UserId,
        id: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      recipeDao.exists(RecipeKey(userId, id)).flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.Recipe.NotFound)
  }

}
