package services.duplication.recipe

import cats.data.OptionT
import cats.effect.unsafe.implicits.global
import db.generated.Tables
import db.{ IngredientId, RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl._
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.common.Transactionally.syntax._
import services.complex.ingredient.{ ComplexIngredient, ComplexIngredientService }
import services.recipe.{ Ingredient, Recipe, RecipeCreation, RecipeService }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slickeffect.catsio.implicits._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._
import utils.date.SimpleDate

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: Duplication.Companion,
    recipeServiceCompanion: RecipeService.Companion,
    complexIngredientServiceCompanion: ComplexIngredientService.Companion
)(implicit
    executionContext: ExecutionContext
) extends Duplication
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def duplicate(
      userId: UserId,
      id: RecipeId
  ): Future[ServerError.Or[Recipe]] = {
    val action = for {
      ingredients        <- recipeServiceCompanion.getIngredients(userId, id)
      complexIngredients <- complexIngredientServiceCompanion.all(userId, Seq(id))
      newIngredients = ingredients.map { ingredient =>
        Duplication.DuplicatedIngredient(
          ingredient = ingredient,
          newId = UUID.randomUUID().transformInto[IngredientId]
        )
      }
      newRecipeId = UUID.randomUUID().transformInto[RecipeId]
      timestamp <- SimpleDate.now.to[DBIO]
      newRecipe <-
        companion.duplicateRecipe(
          userId = userId,
          id = id,
          newId = newRecipeId,
          timestamp = timestamp
        )
      _ <- companion.duplicateIngredients(newRecipeId, newIngredients)
      _ <- companion.duplicateComplexIngredients(newRecipeId, complexIngredients.values.flatten.toSeq)
    } yield newRecipe

    db.runTransactionally(action)
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Creation(error.getMessage).asServerError)
      }
  }

}

object Live {

  class Companion @Inject() (
      recipeServiceCompanion: RecipeService.Companion,
      ingredientDao: db.daos.ingredient.DAO,
      complexIngredientDao: db.daos.complexIngredient.DAO
  ) extends Duplication.Companion {

    override def duplicateRecipe(
        userId: UserId,
        id: RecipeId,
        newId: RecipeId,
        timestamp: SimpleDate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val transformer = for {
        recipe <- OptionT(recipeServiceCompanion.getRecipe(userId, id))
        inserted <- OptionT.liftF(
          recipeServiceCompanion.createRecipe(
            userId = userId,
            id = newId,
            recipeCreation = RecipeCreation(
              name = s"${recipe.name} (copy ${SimpleDate.toPrettyString(timestamp)})",
              description = recipe.description,
              numberOfServings = recipe.numberOfServings,
              servingSize = recipe.servingSize
            )
          )
        )
      } yield inserted

      transformer.getOrElseF(recipeServiceCompanion.notFound)
    }

    override def duplicateIngredients(
        newRecipeId: RecipeId,
        ingredients: Seq[Duplication.DuplicatedIngredient]
    )(implicit ec: ExecutionContext): DBIO[Seq[Ingredient]] =
      ingredientDao
        .insertAll(
          ingredients.map { duplicatedIngredient =>
            val newIngredient = duplicatedIngredient.ingredient.copy(id = duplicatedIngredient.newId)
            (newIngredient, newRecipeId).transformInto[Tables.RecipeIngredientRow]
          }
        )
        .map(_.map(_.transformInto[Ingredient]))

    override def duplicateComplexIngredients(
        newRecipeId: RecipeId,
        complexIngredients: Seq[ComplexIngredient]
    )(implicit ec: ExecutionContext): DBIO[Seq[ComplexIngredient]] =
      complexIngredientDao
        .insertAll {
          complexIngredients.map(
            _.copy(recipeId = newRecipeId)
              .transformInto[Tables.ComplexIngredientRow]
          )
        }
        .map(_.map(_.transformInto[ComplexIngredient]))

  }

}
