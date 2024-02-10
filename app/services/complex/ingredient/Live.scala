package services.complex.ingredient

import cats.data.OptionT
import db.daos.complexFood.ComplexFoodKey
import db.daos.complexIngredient.ComplexIngredientKey
import db.daos.recipe.RecipeKey
import db.generated.Tables
import db.{ ComplexFoodId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.syntax._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.DBError
import services.common.Transactionally.syntax._
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
    db.runTransactionally(companion.all(userId, Seq(recipeId)).map(_.values.flatten.toSeq))

  override def create(
      userId: UserId,
      recipeId: RecipeId,
      complexIngredientCreation: ComplexIngredientCreation
  ): Future[ServerError.Or[ComplexIngredient]] =
    db.runTransactionally(companion.create(userId, recipeId, complexIngredientCreation))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.ComplexIngredient.Creation(error.getMessage).asServerError)
      }

  override def update(
      userId: UserId,
      recipeId: RecipeId,
      complexFoodId: ComplexFoodId,
      complexIngredientUpdate: ComplexIngredientUpdate
  ): Future[ServerError.Or[ComplexIngredient]] =
    db.runTransactionally(companion.update(userId, recipeId, complexFoodId, complexIngredientUpdate))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.ComplexIngredient.Update(error.getMessage).asServerError)
      }

  override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId): Future[Boolean] =
    db.runTransactionally(companion.delete(userId, recipeId, complexFoodId))

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

    override def create(
        userId: UserId,
        recipeId: RecipeId,
        complexIngredientCreation: ComplexIngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val complexIngredient = ComplexIngredientCreation.create(complexIngredientCreation)
      val complexIngredientRow =
        ComplexIngredient
          .TransformableToDB(userId, recipeId, complexIngredient)
          .transformInto[Tables.ComplexIngredientRow]
      withComplexFood(
        userId = userId,
        complexFoodId = complexIngredientCreation.complexFoodId
      ) { complexFoodRow =>
        for {
          createsCycle <- cycleCheck(recipeId, complexIngredientCreation.complexFoodId)
          _            <- if (!createsCycle) DBIO.successful(()) else DBIO.failed(DBError.Complex.Ingredient.Cycle)
          _ <-
            if (isValidScalingMode(complexFoodRow.amountMilliLitres, complexIngredientCreation.scalingMode))
              DBIO.successful(())
            else DBIO.failed(DBError.Complex.Ingredient.ScalingModeMismatch)
          row <- complexIngredientDao.insert(complexIngredientRow)
        } yield row.transformInto[ComplexIngredient]
      }
    }

    override def update(
        userId: UserId,
        recipeId: RecipeId,
        complexFoodId: ComplexFoodId,
        complexIngredientUpdate: ComplexIngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[ComplexIngredient] = {
      val findAction = OptionT(
        complexIngredientDao.find(
          ComplexIngredientKey(userId, recipeId, complexFoodId)
        )
      ).map(_.transformInto[ComplexIngredient])
        .getOrElseF(DBIO.failed(DBError.Complex.Ingredient.NotFound))

      for {
        complexIngredient <- findAction
        _ <- withComplexFood(
          userId = userId,
          complexFoodId = complexFoodId
        ) { complexFoodRow =>
          if (isValidScalingMode(complexFoodRow.amountMilliLitres, complexIngredientUpdate.scalingMode)) {
            val updated = ComplexIngredientUpdate.update(complexIngredient, complexIngredientUpdate)
            complexIngredientDao.update(
              ComplexIngredient
                .TransformableToDB(userId, recipeId, updated)
                .transformInto[Tables.ComplexIngredientRow]
            )
          } else DBIO.failed(DBError.Complex.Ingredient.ScalingModeMismatch)
        }
        updatedIngredient <- findAction
      } yield updatedIngredient
    }

    override def delete(userId: UserId, recipeId: RecipeId, complexFoodId: ComplexFoodId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      for {
        exists <- recipeDao.exists(RecipeKey(userId, recipeId))
        result <-
          if (exists)
            complexIngredientDao
              .delete(ComplexIngredientKey(userId, recipeId, complexFoodId))
              .map(_ > 0)
          else DBIO.successful(false)
      } yield result

    private def withComplexFood[A](
        userId: UserId,
        complexFoodId: ComplexFoodId
    )(action: Tables.ComplexFoodRow => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      for {
        complexFoodCandidate <- complexFoodDao.find(ComplexFoodKey(userId, complexFoodId))
        result <- complexFoodCandidate.fold(DBIO.failed(DBError.Complex.Ingredient.NotFound): DBIO[A])(action)
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

    private def isValidScalingMode(
        volumeAmount: Option[BigDecimal],
        scalingMode: ScalingMode
    ): Boolean = (volumeAmount, scalingMode) match {
      case (None, ScalingMode.Volume) => false
      case _                          => true
    }

  }

}
