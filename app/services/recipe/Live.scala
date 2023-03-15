package services.recipe

import cats.Applicative
import cats.data.OptionT
import db.daos.recipe.RecipeKey
import db.generated.Tables
import db.{ FoodId, IngredientId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.GeneralTableConstants
import services.common.Transactionally.syntax._
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.collection.MapUtil

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

  override def allFoods: Future[Seq[Food]] = db.runTransactionally(companion.allFoods)

  override def getFoodInfo(foodId: FoodId): Future[Option[FoodInfo]] =
    db.runTransactionally(companion.getFoodInfo(foodId))

  override def allMeasures: Future[Seq[Measure]] = db.runTransactionally(companion.allMeasures)

  override def allRecipes(userId: UserId): Future[Seq[Recipe]] = db.runTransactionally(companion.allRecipes(userId))

  override def getRecipe(
      userId: UserId,
      id: RecipeId
  ): Future[Option[Recipe]] =
    db.runTransactionally(companion.getRecipe(userId, id))

  override def createRecipe(
      userId: UserId,
      recipeCreation: RecipeCreation
  ): Future[ServerError.Or[Recipe]] = {
    db.runTransactionally(companion.createRecipe(userId, UUID.randomUUID().transformInto[RecipeId], recipeCreation))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Creation(error.getMessage).asServerError)
      }
  }

  override def updateRecipe(
      userId: UserId,
      recipeUpdate: RecipeUpdate
  ): Future[ServerError.Or[Recipe]] =
    db.runTransactionally(companion.updateRecipe(userId, recipeUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Update(error.getMessage).asServerError)
      }

  override def deleteRecipe(
      userId: UserId,
      id: RecipeId
  ): Future[Boolean] = db.runTransactionally(companion.deleteRecipe(userId, id))

  override def getIngredients(userId: UserId, recipeId: RecipeId): Future[List[Ingredient]] =
    db.runTransactionally(companion.getIngredients(userId, recipeId))

  override def addIngredient(
      userId: UserId,
      ingredientCreation: IngredientCreation
  ): Future[ServerError.Or[Ingredient]] =
    db.runTransactionally(
      companion.addIngredient(userId, UUID.randomUUID().transformInto[IngredientId], ingredientCreation)
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Ingredient.Creation(error.getMessage).asServerError)
      }

  override def updateIngredient(
      userId: UserId,
      ingredientUpdate: IngredientUpdate
  ): Future[ServerError.Or[Ingredient]] =
    db.runTransactionally(companion.updateIngredient(userId, ingredientUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Ingredient.Update(error.getMessage).asServerError)
      }

  override def removeIngredient(userId: UserId, ingredientId: IngredientId): Future[Boolean] =
    db.runTransactionally(companion.removeIngredient(userId, ingredientId))
      .recover { _ =>
        false
      }

}

object Live {

  class Companion @Inject() (
      recipeDao: db.daos.recipe.DAO,
      ingredientDao: db.daos.ingredient.DAO,
      generalTableConstants: GeneralTableConstants
  ) extends RecipeService.Companion {

    def allFoods: DBIO[Seq[Food]] = DBIO.successful {
      generalTableConstants.allFoodNames.map { food =>
        val allMeasureIds = AmountUnit.hundredGrams +: generalTableConstants.allConversionFactors.collect {
          case ((foodId, measureId), _) if foodId == food.foodId => measureId
        }.toList
        val measures = generalTableConstants.allMeasureNames.filter { measureRow =>
          allMeasureIds.contains(measureRow.measureId)
        }
        (food -> measures.toList).transformInto[Food]
      }
    }

    override def getFoodInfo(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[FoodInfo]] =
      Tables.FoodName
        .filter(_.foodId === foodId.transformInto[Int])
        .result
        .headOption
        .map(_.map(_.transformInto[FoodInfo]))

    override val allMeasures: DBIO[Seq[Measure]] =
      DBIO.successful(generalTableConstants.allMeasureNames.map(_.transformInto[Measure]))

    override def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]] =
      recipeDao
        .findAllFor(userId)
        .map(
          _.map(_.transformInto[Recipe])
        )

    override def getRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[Recipe]] =
      OptionT(
        recipeDao.find(RecipeKey(userId, id))
      ).map(_.transformInto[Recipe]).value

    override def getRecipes(
        userId: UserId,
        ids: Seq[RecipeId]
    )(implicit ec: ExecutionContext): DBIO[Seq[Recipe]] =
      recipeDao
        .allOf(userId, ids)
        .map(_.map(_.transformInto[Recipe]))

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
        )
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
              .findAllFor(Seq(recipeId))
              .map(_.map(_.transformInto[Ingredient]).toList)
          else Applicative[DBIO].pure(List.empty)
      } yield ingredients

    override def getAllIngredients(userId: UserId, recipeIds: Seq[RecipeId])(implicit
        ec: ExecutionContext
    ): DBIO[Map[RecipeId, List[Ingredient]]] = {
      for {
        matchingRecipes <- recipeDao.allOf(userId, recipeIds)
        typedIds = matchingRecipes.map(_.id.transformInto[RecipeId])
        allIngredients <- ingredientDao.findAllFor(typedIds)
      } yield {
        // GroupBy skips recipes with no entries, hence they are added manually afterwards.
        val preMap = allIngredients.groupBy(_.recipeId.transformInto[RecipeId])
        MapUtil
          .unionWith(preMap, typedIds.map(_ -> Seq.empty).toMap)((x, _) => x)
          .view
          .mapValues(_.map(_.transformInto[Ingredient]).toList)
          .toMap
      }
    }

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
          )
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
