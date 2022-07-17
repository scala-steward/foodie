package services.recipe

import cats.data.{ EitherT, OptionT }
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.user.UserId
import shapeless.tag.@@
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.IdUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait RecipeService {
  def allFoods: Future[Seq[Food]]
  def allMeasures: Future[Seq[Measure]]

  def getRecipe(id: UUID @@ RecipeId): Future[Option[Recipe]]
  def createRecipe(userId: UUID @@ UserId, recipeCreation: RecipeCreation): Future[Recipe]
  def updateRecipe(recipeUpdate: RecipeUpdate): Future[ServerError.Or[Recipe]]
  def deleteRecipe(id: UUID @@ RecipeId): Future[Boolean]

  def addIngredient(addIngredient: AddIngredient): Future[ServerError.Or[Ingredient]]
  def removeIngredient(ingredientId: UUID @@ IngredientId): Future[Boolean]
  def updateAmount(ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Ingredient]]
}

object RecipeService {

  trait Companion {
    def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]]
    def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]]

    def getRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Option[Recipe]]

    def createRecipe(
        id: UUID @@ RecipeId,
        userId: UUID @@ UserId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def updateRecipe(recipeUpdate: RecipeUpdate)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Recipe]]
    def deleteRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean]

    def addIngredient(id: UUID @@ IngredientId, addIngredient: AddIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def removeIngredient(id: UUID @@ IngredientId)(implicit ec: ExecutionContext): DBIO[Boolean]

    def updateAmount(ingredientUpdate: IngredientUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ServerError.Or[Ingredient]]

  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends RecipeService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allFoods: Future[Seq[Food]] = db.run(companion.allFoods)

    override def allMeasures: Future[Seq[Measure]] = db.run(companion.allMeasures)

    override def getRecipe(id: UUID @@ RecipeId): Future[Option[Recipe]] =
      db.run(companion.getRecipe(id))

    override def createRecipe(userId: UUID @@ UserId, recipeCreation: RecipeCreation): Future[Recipe] = {
      db.run(companion.createRecipe(UUID.randomUUID().transformInto[UUID @@ RecipeId], userId, recipeCreation))
    }

    override def updateRecipe(recipeUpdate: RecipeUpdate): Future[ServerError.Or[Recipe]] =
      db.run(companion.updateRecipe(recipeUpdate))

    override def deleteRecipe(id: UUID @@ RecipeId): Future[Boolean] = db.run(companion.deleteRecipe(id))

    override def addIngredient(addIngredient: AddIngredient): Future[ServerError.Or[Ingredient]] =
      db.run(companion.addIngredient(UUID.randomUUID().transformInto[UUID @@ IngredientId], addIngredient))
        .map(Right(_))
        .recover {
          case error =>
            Left(ErrorContext.Recipe.Ingredient.Creation(error.getMessage).asServerError)
        }

    override def removeIngredient(ingredientId: UUID @@ IngredientId): Future[Boolean] =
      db.run(companion.removeIngredient(ingredientId))

    override def updateAmount(ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Ingredient]] =
      db.run(companion.updateAmount(ingredientUpdate))

  }

  object Live extends Companion {

    override def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]] =
      Tables.FoodName.result
        .map(_.map(_.transformInto[Food]))

    override def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
      Tables.MeasureName.result
        .map(_.map(_.transformInto[Measure]))

    override def getRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Option[Recipe]] = {
      val recipeId = id.transformInto[UUID]

      val transformer = for {
        recipeRow <- OptionT(Tables.Recipe.filter(_.id === recipeId).result.headOption: DBIO[Option[Tables.RecipeRow]])
        ingredientRows <- OptionT.liftF(
          Tables.RecipeIngredient.filter(_.recipeId === recipeId).result: DBIO[Seq[Tables.RecipeIngredientRow]]
        )
      } yield Recipe
        .DBRepresentation(
          recipeRow,
          ingredientRows
        )
        .transformInto[Recipe]

      transformer.value
    }

    override def createRecipe(
        id: UUID @@ RecipeId,
        userId: UUID @@ UserId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val recipe = RecipeCreation.create(id, recipeCreation)
      val recipeRow = Tables.RecipeRow(
        id = recipe.id.transformInto[UUID],
        userId = userId.transformInto[UUID],
        name = recipe.name,
        description = recipe.description
      )
      (Tables.Recipe.returning(Tables.Recipe) += recipeRow)
        .map { recipeRow =>
          val dbRepresentation = Recipe.DBRepresentation(recipeRow = recipeRow, ingredientRows = Seq.empty)
          dbRepresentation.transformInto[Recipe]
        }
    }

    // TODO: Bottleneck - updates concern only the description, however the full recipe is fetched again.
    override def updateRecipe(recipeUpdate: RecipeUpdate)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Recipe]] =
      Tables.Recipe
        .filter(_.id === recipeUpdate.id.transformInto[UUID])
        .map(r => (r.name, r.description))
        .update((recipeUpdate.name, recipeUpdate.description))
        .andThen(
          getRecipe(recipeUpdate.id)
            .map(_.toRight(ErrorContext.Recipe.NotFound.asServerError))
        )

    override def deleteRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
      Tables.Recipe
        .filter(_.id === id.transformInto[UUID])
        .delete
        .map(_ > 0)

    override def addIngredient(id: UUID @@ IngredientId, addIngredient: AddIngredient)(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] =
      (Tables.RecipeIngredient.returning(Tables.RecipeIngredient) += AddIngredient.create(id, addIngredient))
        .map(_.transformInto[Ingredient])

    override def removeIngredient(
        id: UUID @@ IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean] =
      Tables.RecipeIngredient
        .filter(_.id === id.transformInto[UUID])
        .delete
        .map(_ > 0)

    override def updateAmount(ingredientUpdate: IngredientUpdate)(implicit
        ec: ExecutionContext
    ): DBIO[ServerError.Or[Ingredient]] = {
      val findAction = Tables.RecipeIngredient
        .filter(_.id === ingredientUpdate.id.transformInto[UUID])
      findAction
        .map(i => (i.measureId, i.factor))
        .update((ingredientUpdate.amountUnit.measureId.transformInto[Int], ingredientUpdate.amountUnit.factor))
        .andThen(
          EitherT
            .fromOptionF(
              findAction.result.headOption: DBIO[Option[Tables.RecipeIngredientRow]],
              ErrorContext.Recipe.Ingredient.NotFound.asServerError
            )
            .map(_.transformInto[Ingredient])
            .value
        )
    }

  }

}
