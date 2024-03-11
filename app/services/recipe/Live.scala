package services.recipe

import cats.Applicative
import cats.data.OptionT
import db.daos.ingredient.IngredientKey
import db.daos.recipe.RecipeKey
import db.generated.Tables
import db.{ FoodId, IngredientId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.syntax._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.GeneralTableConstants
import services.common.Transactionally.syntax._
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
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
      id: RecipeId,
      recipeUpdate: RecipeUpdate
  ): Future[ServerError.Or[Recipe]] =
    db.runTransactionally(companion.updateRecipe(userId, id, recipeUpdate))
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
      recipeId: RecipeId,
      ingredientCreation: IngredientCreation
  ): Future[ServerError.Or[Ingredient]] =
    db.runTransactionally(
      companion.addIngredient(userId, recipeId, UUID.randomUUID().transformInto[IngredientId], ingredientCreation)
    ).map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Ingredient.Creation(error.getMessage).asServerError)
      }

  override def updateIngredient(
      userId: UserId,
      recipeId: RecipeId,
      ingredientId: IngredientId,
      ingredientUpdate: IngredientUpdate
  ): Future[ServerError.Or[Ingredient]] =
    db.runTransactionally(companion.updateIngredient(userId, recipeId, ingredientId, ingredientUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Ingredient.Update(error.getMessage).asServerError)
      }

  override def removeIngredient(userId: UserId, recipeId: RecipeId, ingredientId: IngredientId): Future[Boolean] =
    db.runTransactionally(companion.removeIngredient(userId, recipeId, ingredientId))
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
      val recipeRow = Recipe.TransformableToDB(userId, recipe).transformInto[Tables.RecipeRow]
      recipeDao
        .insert(recipeRow)
        .map(_.transformInto[Recipe])
    }

    override def updateRecipe(
        userId: UserId,
        id: RecipeId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val findAction = OptionT(getRecipe(userId, id)).getOrElseF(notFound)
      for {
        recipe <- findAction
        _ <- recipeDao.update(
          Recipe
            .TransformableToDB(
              userId,
              RecipeUpdate.update(recipe, recipeUpdate)
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
              .findAllFor(userId, Seq(recipeId))
              .map(_.map(_.transformInto[Ingredient]).toList)
          else Applicative[DBIO].pure(List.empty)
      } yield ingredients

    override def getAllIngredients(userId: UserId, recipeIds: Seq[RecipeId])(implicit
        ec: ExecutionContext
    ): DBIO[Map[RecipeId, List[Ingredient]]] = {
      for {
        matchingRecipes <- recipeDao.allOf(userId, recipeIds)
        typedIds = matchingRecipes.map(_.id.transformInto[RecipeId])
        allIngredients <- ingredientDao.findAllFor(userId, typedIds)
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
        recipeId: RecipeId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val ingredient = IngredientCreation.create(id, ingredientCreation)
      val ingredientRow = Ingredient
        .TransformableToDB(userId, recipeId, ingredient)
        .transformInto[Tables.RecipeIngredientRow]
      ingredientDao
        .insert(ingredientRow)
        .map(_.transformInto[Ingredient])

    }

    override def updateIngredient(
        userId: UserId,
        recipeId: RecipeId,
        ingredientId: IngredientId,
        ingredientUpdate: IngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val findAction =
        OptionT(ingredientDao.find(IngredientKey(userId, recipeId, ingredientId)))
          .getOrElseF(DBIO.failed(DBError.Recipe.IngredientNotFound))
      for {
        ingredientRow <- findAction
        _ <- ingredientDao.update(
          Ingredient
            .TransformableToDB(
              userId,
              ingredientRow.recipeId.transformInto[RecipeId],
              IngredientUpdate.update(ingredientRow.transformInto[Ingredient], ingredientUpdate)
            )
            .transformInto[Tables.RecipeIngredientRow]
        )
        updatedIngredientRow <- findAction
      } yield updatedIngredientRow.transformInto[Ingredient]
    }

    override def removeIngredient(
        userId: UserId,
        recipeId: RecipeId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean] =
      ingredientDao
        .delete(IngredientKey(userId, recipeId, id))
        .map(_ > 0)

  }

}
