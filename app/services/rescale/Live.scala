package services.rescale

import cats.data.{ EitherT, NonEmptyList, Validated, ValidatedNel }
import db.{ RecipeId, UserId }
import errors.{ ErrorContext, ServerError }
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.recipe.{ Recipe, RecipeService, RecipeUpdate }
import services.rescale
import slick.jdbc.PostgresProfile
import services.common.Transactionally.syntax._
import services.stats.StatsService
import slick.dbio.DBIO
import utils.DBIOUtil.instances._
import cats.syntax.contravariantSemigroupal._

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }
import scala.util.Try
import scala.util.chaining.scalaUtilChainingOps

class Live @Inject() (
    override protected val dbConfigProvider: DatabaseConfigProvider,
    companion: rescale.RescaleService.Companion
)(implicit
    ec: ExecutionContext
) extends RescaleService
    with HasDatabaseConfigProvider[PostgresProfile] {

  override def rescale(
      userId: UserId,
      recipeId: RecipeId
  ): Future[ServerError.Or[Recipe]] =
    db.runTransactionally(companion.rescale(userId, recipeId))
      .map(Right(_))
      .recover { case error =>
        Left(ErrorContext.Recipe.Update(error.getMessage).asServerError)
      }

}

object Live {

  class Companion @Inject() (
      recipeService: RecipeService.Companion,
      statsService: StatsService.Companion
  ) extends RescaleService.Companion {

    override def rescale(
        userId: UserId,
        recipeId: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Recipe] = {
      val transformer = for {
        recipe <- EitherT.fromOptionF(
          recipeService.getRecipe(userId, recipeId),
          ErrorContext.Recipe.NotFound.asServerError
        )
        scalable <- EitherT.fromEither[DBIO](
          recipe.servingSize
            .toRight(ErrorContext.Recipe.AutoScale("No serving size set").asServerError)
            .flatMap(
              toGramWeight(_).toEither.left.map(
                _.toList
                  .mkString(", ")
                  .pipe(ErrorContext.Recipe.AutoScale.apply)
                  .pipe(_.asServerError)
              )
            )
        )
        fullWeight <- EitherT.fromOptionF(
          statsService.weightOfRecipe(userId, recipeId),
          ErrorContext.Recipe.NotFound.asServerError
        )
        numberOfServings = fullWeight / scalable
        updated <- EitherT.liftF[DBIO, ServerError, Recipe](
          recipeService.updateRecipe(
            userId,
            recipeId,
            RecipeUpdate(
              name = recipe.name,
              description = recipe.description,
              numberOfServings = numberOfServings,
              servingSize = recipe.servingSize
            )
          )
        )
      } yield updated

      transformer.foldF(
        error => DBIO.failed(new Throwable(error.message)),
        DBIO.successful
      )
    }

  }

  private def toGramWeight(string: String): ValidatedNel[String, BigDecimal] = {
    val init = string.dropRight(1).trim
    val last = string.lastOption.map(_.toLower)

    val nonEmpty = Validated.condNel(string.nonEmpty, (), "Expected non-empty serving size")
    val unitMatches =
      Validated.condNel(last.contains('g'), (), s"Expected unit to be 'g', but got '${last.fold("")(c => s"$c")}'")
    val numberMatches = Validated
      .fromTry(Try(BigDecimal(init)).filter(_ > 0))
      .leftMap(
        _.getMessage.pipe(NonEmptyList.of(_))
      )

    (
      nonEmpty,
      unitMatches,
      numberMatches
    ).mapN { (_, _, number) =>
      number
    }
  }

}
