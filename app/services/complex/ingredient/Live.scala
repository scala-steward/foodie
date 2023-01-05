package services.complex.ingredient

import cats.Applicative
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

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: ComplexIngredientService.Companion
)(implicit ec: ExecutionContext)
    extends ComplexIngredientService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def all(userId: UserId, recipeId: RecipeId): Future[Seq[ComplexIngredient]] =
    db.run(companion.all(userId, recipeId))

  override def create(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]] =
    db.run(companion.create(userId, complexIngredient))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.Recipe.ComplexIngredient.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      complexIngredient: ComplexIngredient
  ): Future[ServerError.Or[ComplexIngredient]] =
    db.run(companion.update(userId, complexIngredient))
      .map(Right(_))
      .recover {
        case error =>
          Left(ErrorContext.Recipe.ComplexIngredient.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId): Future[Boolean] =
    db.run(companion.delete(userId, recipeId, complexFoodId))

}

object Live {

  class Companion @Inject() (
      recipeDao: db.daos.recipe.DAO,
      dao: db.daos.complexIngredient.DAO
  ) extends ComplexIngredientService.Companion {

    override def all(userId: UserId, recipeId: RecipeId)(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]] =
      for {
        exists <- recipeDao.exists(RecipeKey(userId, recipeId))
        complexIngredients <-
          if (exists)
            dao.findBy(_.recipeId === recipeId.transformInto[UUID])
          else Applicative[DBIO].pure(List.empty)
      } yield complexIngredients.map(_.transformInto[ComplexIngredient])

    override def create(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val complexIngredientRow = complexIngredient.transformInto[Tables.ComplexIngredientRow]
      ifRecipeExists(userId, complexIngredient.recipeId) {
        for {
          createsCycle <- cycleCheck(complexIngredient.recipeId, complexIngredient.complexFoodId)
          _            <- if (!createsCycle) DBIO.successful(()) else DBIO.failed(DBError.Complex.Ingredient.Cycle)
          row          <- dao.insert(complexIngredientRow)
        } yield row.transformInto[ComplexIngredient]
      }
    }

    override def update(userId: UserId, complexIngredient: ComplexIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val key = ComplexIngredientKey(complexIngredient.recipeId, complexIngredient.complexFoodId)
      for {
        _ <- dao.exists(key)
        _ <- ifRecipeExists(userId, complexIngredient.recipeId) {
          dao
            .update(complexIngredient.transformInto[Tables.ComplexIngredientRow])(ComplexIngredientKey.of)
        }
        updatedIngredient <- dao.find(key)
      } yield updatedIngredient.transformInto[ComplexIngredient]
    }

    override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      dao
        .delete(ComplexIngredientKey(recipeId, complexFoodId))
        .map(_ > 0)

    private def ifRecipeExists[A](
        userId: UserId,
        recipeId: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      recipeDao
        .exists(RecipeKey(userId, recipeId))
        .flatMap(exists => if (exists) action else DBIO.failed(DBError.Complex.Ingredient.RecipeNotFound))

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
