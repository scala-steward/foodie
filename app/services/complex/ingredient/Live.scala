package services.complex.ingredient

import cats.data.OptionT
import db.daos.complexIngredient.ComplexIngredientKey
import db.daos.recipe.RecipeKey
import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.CycleCheck
import utils.CycleCheck.Arc
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.collection.MapUtil

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: ComplexIngredientService.Companion
)(implicit ec: ExecutionContext)
    extends ComplexIngredientService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all(userId: UserId, recipeId: RecipeId): Future[Seq[ComplexIngredient]] =
    db.run(companion.all(userId, Seq(recipeId)).map(_.values.flatten.toSeq))

  override def create(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]] =
    db.run(companion.create(userId, complexIngredient))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.ComplexIngredient.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]] =
    db.run(companion.update(userId, complexIngredient))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.ComplexIngredient.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId): Future[Boolean] =
    db.run(companion.delete(userId, recipeId, complexFoodId))

}

object Live {

  class Companion @Inject() (
      recipeDao: db.daos.recipe.DAO,
      complexFoodDao: db.daos.complexFood.DAO,
      complexIngredientDao: db.daos.complexIngredient.DAO
  ) extends ComplexIngredientService.Companion {

    override def all(userId: UserId, recipeIds: Seq[RecipeId])(implicit
        ec: ExecutionContext
    ): DBIO[Map[RecipeId, Seq[ComplexIngredient]]] =
      for {
        matchingRecipes <- recipeDao.allOf(userId, recipeIds)
        typedIds = matchingRecipes.map(_.id.transformInto[RecipeId])
        // TODO: Reconsider the conversion from and to RecipeId here and in the DAO.
        complexIngredients <- complexIngredientDao.findAllFor(typedIds)
      } yield {
        // GroupBy skips recipes with no entries, hence they are added manually afterwards.
        val preMap = complexIngredients.groupBy(_.recipeId.transformInto[RecipeId])
        MapUtil
          .unionWith(preMap, typedIds.map(_ -> Seq.empty).toMap)((x, _) => x)
          .view
          .mapValues(_.map(_.transformInto[ComplexIngredient]))
          .toMap
      }

    override def create(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val complexIngredientRow = complexIngredient.transformInto[Tables.ComplexIngredientRow]
      ifRecipeAndComplexFoodExist(
        userId = userId,
        recipeId = complexIngredient.recipeId,
        complexFoodId = complexIngredient.complexFoodId
      ) {
        for {
          createsCycle <- cycleCheck(complexIngredient.recipeId, complexIngredient.complexFoodId)
          _            <- if (!createsCycle) DBIO.successful(()) else DBIO.failed(DBError.Complex.Ingredient.Cycle)
          row          <- complexIngredientDao.insert(complexIngredientRow)
        } yield row.transformInto[ComplexIngredient]
      }
    }

    override def update(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val findAction = OptionT(
        complexIngredientDao.find(ComplexIngredientKey(complexIngredient.recipeId, complexIngredient.complexFoodId))
      ).getOrElseF(DBIO.failed(DBError.Complex.Ingredient.NotFound))

      for {
        _ <- findAction
        _ <- ifRecipeAndComplexFoodExist(
          userId = userId,
          recipeId = complexIngredient.recipeId,
          complexFoodId = complexIngredient.complexFoodId
        ) {
          complexIngredientDao.update(complexIngredient.transformInto[Tables.ComplexIngredientRow])
        }
        updatedIngredient <- findAction
      } yield updatedIngredient.transformInto[ComplexIngredient]
    }

    override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      for {
        exists <- recipeDao.exists(RecipeKey(userId, recipeId))
        result <-
          if (exists)
            complexIngredientDao
              .delete(ComplexIngredientKey(recipeId, complexFoodId))
              .map(_ > 0)
          else DBIO.successful(false)
      } yield result

    private def ifRecipeAndComplexFoodExist[A](
        userId: UserId,
        recipeId: RecipeId,
        complexFoodId: ComplexFoodId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      for {
        recipeExists      <- recipeDao.exists(RecipeKey(userId, recipeId))
        complexFoodExists <- complexFoodDao.exists(complexFoodId)
        result <-
          if (!recipeExists) DBIO.failed(DBError.Complex.Ingredient.RecipeNotFound)
          else if (!complexFoodExists) DBIO.failed(DBError.Complex.Ingredient.NotFound)
          else action
      } yield result

    private def cycleCheck(recipeId: RecipeId, newReferenceRecipeId: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] = {
      val action =
        sql"""with recursive transitive_references as (
                select recipe_id, complex_food_id
                from complex_ingredient
                where recipe_id = ${newReferenceRecipeId.toString} :: uuid
                  union
                    select ci.recipe_id, ci.complex_food_id
                      from complex_ingredient ci
                      inner join transitive_references r on r.complex_food_id = ci.recipe_id
              )
                select recipe_id, complex_food_id from transitive_references;"""
          .as[(String, String)]

      action.map { rows =>
        val graph = CycleCheck.fromArcs(Arc(recipeId.toString, newReferenceRecipeId.toString) +: rows.map {
          case (s1, s2) => Arc(s1, s2)
        })
        CycleCheck.onCycle(recipeId.toString, graph)
      }

    }

  }

}
