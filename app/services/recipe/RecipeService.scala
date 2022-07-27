package services.recipe

import cats.data.OptionT
import cats.syntax.traverse._
import db.generated.Tables
import errors.{ ErrorContext, ServerError }
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.{ FoodId, IngredientId, RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait RecipeService {
  def allFoods(search: Option[String]): Future[Seq[Food]]
  def allMeasures: Future[Seq[Measure]]

  def allRecipes(userId: UserId): Future[Seq[Recipe]]
  def getRecipe(userId: UserId, id: RecipeId): Future[Option[Recipe]]
  def createRecipe(userId: UserId, recipeCreation: RecipeCreation): Future[ServerError.Or[Recipe]]
  def updateRecipe(userId: UserId, recipeUpdate: RecipeUpdate): Future[ServerError.Or[Recipe]]
  def deleteRecipe(userId: UserId, id: RecipeId): Future[Boolean]

  def addIngredient(userId: UserId, ingredientCreation: IngredientCreation): Future[ServerError.Or[Ingredient]]
  def updateIngredient(userId: UserId, ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Ingredient]]
  def removeIngredient(userId: UserId, ingredientId: IngredientId): Future[Boolean]

  def measuresFor(foodId: FoodId): Future[Seq[Measure]]
}

object RecipeService {

  trait Companion {
    def allFoods(search: Option[String])(implicit ec: ExecutionContext): DBIO[Seq[Food]]
    def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]]

    def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]]

    def getRecipe(
        userId: UserId,
        id: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Option[Recipe]]

    def createRecipe(
        userId: UserId,
        id: RecipeId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def deleteRecipe(
        userId: UserId,
        id: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    def addIngredient(
        userId: UserId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def updateIngredient(
        userId: UserId,
        ingredientUpdate: IngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def removeIngredient(
        userId: UserId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    def measuresFor(
        foodId: FoodId
    )(implicit ec: ExecutionContext): DBIO[Seq[Measure]]

  }

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      executionContext: ExecutionContext
  ) extends RecipeService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def allFoods(search: Option[String]): Future[Seq[Food]] = db.run(companion.allFoods(search))

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

    override def measuresFor(foodId: FoodId): Future[Seq[Measure]] = db.run(companion.measuresFor(foodId))
  }

  object Live extends Companion {

    override def allFoods(search: Option[String])(implicit ec: ExecutionContext): DBIO[Seq[Food]] = {
      val filter: Tables.FoodName => Rep[Boolean] =
        search.filter(_.nonEmpty).fold((_: Tables.FoodName) => true: Rep[Boolean]) { string =>
          val queryString                             = s"%${string.toLowerCase}%"
          def likeSearch: Rep[String] => Rep[Boolean] = _.toLowerCase.like(queryString)
          t =>
            likeSearch(t.foodDescription) ||
              likeSearch(t.foodDescriptionF) ||
              likeSearch(t.scientificName.getOrElse(""))
        }
      Tables.FoodName
        .filter(filter)
        .result
        .map(_.map(_.transformInto[Food]))
    }

    override def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
      Tables.MeasureName.result
        .map(_.map(_.transformInto[Measure]))

    override def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]] =
      Tables.Recipe
        .filter(_.userId === userId.transformInto[UUID])
        .map(_.id)
        .result
        .flatMap(
          _.traverse(id => getRecipe(userId, id.transformInto[RecipeId]))
        )
        .map(_.flatten)

    override def getRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Option[Recipe]] = {
      val recipeId = id.transformInto[UUID]

      val transformer = for {
        recipeRow <- OptionT(
          recipeQuery(userId, id).result.headOption: DBIO[Option[Tables.RecipeRow]]
        )
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
        userId: UserId,
        id: RecipeId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val recipe           = RecipeCreation.create(id, recipeCreation)
      val dbRepresentation = (recipe, userId).transformInto[Recipe.DBRepresentation]
      (Tables.Recipe.returning(Tables.Recipe) += dbRepresentation.recipeRow)
        .map { recipeRow =>
          dbRepresentation
            .copy(recipeRow = recipeRow)
            .transformInto[Recipe]
        }
    }

    // TODO: Bottleneck - updates concern only the non-ingredient parts, but the full recipe is fetched again.
    override def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe] = {
      val findAction = OptionT(getRecipe(userId, recipeUpdate.id)).getOrElseF(DBIO.failed(DBError.RecipeNotFound))
      for {
        recipe <- findAction
        _ <- recipeQuery(userId, recipeUpdate.id).update(
          (
            RecipeUpdate
              .update(recipe, recipeUpdate),
            userId
          )
            .transformInto[Recipe.DBRepresentation]
            .recipeRow
        )
        updatedRecipe <- findAction
      } yield updatedRecipe
    }

    override def deleteRecipe(userId: UserId, id: RecipeId)(implicit
        ec: ExecutionContext
    ): DBIO[Boolean] =
      recipeQuery(userId, id).delete
        .map(_ > 0)

    override def addIngredient(
        userId: UserId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient] = {
      val ingredient = IngredientCreation.create(id, ingredientCreation)
      ifRecipeExists(userId, ingredientCreation.recipeId) {
        (Tables.RecipeIngredient
          .returning(Tables.RecipeIngredient) += (ingredient, ingredientCreation.recipeId)
          .transformInto[Tables.RecipeIngredientRow])
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
        OptionT(ingredientQuery(ingredientUpdate.id).result.headOption: DBIO[Option[Tables.RecipeIngredientRow]])
          .getOrElseF(DBIO.failed(DBError.RecipeIngredientNotFound))
      for {
        ingredientRow <- findAction
        _ <- ingredientQuery(ingredientUpdate.id).update(
          (
            IngredientUpdate
              .update(ingredientRow.transformInto[Ingredient], ingredientUpdate),
            ingredientRow.recipeId.transformInto[RecipeId]
          )
            .transformInto[Tables.RecipeIngredientRow]
        )
        updatedIngredientRow <- findAction
      } yield updatedIngredientRow.transformInto[Ingredient]
    }

    override def removeIngredient(
        userId: UserId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean] =
      OptionT(
        ingredientQuery(id)
          .map(_.recipeId)
          .result
          .headOption: DBIO[Option[UUID]]
      )
        .semiflatMap(recipeId =>
          ifRecipeExists(userId, recipeId.transformInto[RecipeId]) {
            ingredientQuery(id).delete
              .map(_ > 0)
          }
        )
        .getOrElse(false)

    override def measuresFor(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
      for {
        measureIds <-
          Tables.ConversionFactor
            .filter(_.foodId === foodId.transformInto[Int])
            .map(_.measureId)
            .result
        measureRows <- Tables.MeasureName.filter(_.measureId.inSetBind(measureIds)).result
      } yield measureRows.map(_.transformInto[Measure])

    private def recipeQuery(
        userId: UserId,
        id: RecipeId
    ): Query[Tables.Recipe, Tables.RecipeRow, Seq] =
      Tables.Recipe
        .filter(r =>
          r.id === id.transformInto[UUID] &&
            r.userId === userId.transformInto[UUID]
        )

    private def ingredientQuery(
        ingredientId: IngredientId
    ): Query[Tables.RecipeIngredient, Tables.RecipeIngredientRow, Seq] =
      Tables.RecipeIngredient
        .filter(_.id === ingredientId.transformInto[UUID])

    private def ifRecipeExists[A](
        userId: UserId,
        id: RecipeId
    )(action: => DBIO[A])(implicit ec: ExecutionContext): DBIO[A] =
      recipeQuery(userId, id).exists.result.flatMap(exists => if (exists) action else notFound)

    private def notFound[A]: DBIO[A] = DBIO.failed(DBError.RecipeNotFound)
  }

}
