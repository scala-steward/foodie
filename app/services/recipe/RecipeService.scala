package services.recipe

import db.generated.Tables
import errors.ServerError
import errors.ServerError.Or
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import shapeless.tag.@@
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._

import java.util.UUID
import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait RecipeService {
  def allFoods: Future[Seq[Food]]
  def allMeasures: Future[Seq[Measure]]

  def getRecipe(id: UUID @@ RecipeId): Future[Option[Recipe]]
  def createRecipe(recipeCreation: RecipeCreation): Future[Recipe]
  def updateRecipe(recipeUpdate: RecipeUpdate): Future[Recipe]
  def deleteRecipe(id: UUID @@ RecipeId): Future[ServerError.Or[Unit]]

  def addIngredient(addIngredient: AddIngredient): Future[ServerError.Or[Unit]]
  def removeIngredient(ingredientId: UUID @@ IngredientId): Future[ServerError.Or[Unit]]
  def updateAmount(ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Unit]]
}

object RecipeService {

  trait Companion {
    def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]]
    def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]]

    def getRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Option[Recipe]]
    def createRecipe(recipeCreation: RecipeCreation)(implicit ec: ExecutionContext): DBIO[Recipe]
    def updateRecipe(recipeUpdate: RecipeUpdate)(implicit ec: ExecutionContext): DBIO[Recipe]
    def deleteRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Unit]]

    def addIngredient(addIngredient: AddIngredient)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Unit]]
    def removeIngredient(ingredientId: UUID @@ IngredientId)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Unit]]
    def updateAmount(ingredientUpdate: IngredientUpdate)(implicit ec: ExecutionContext): DBIO[ServerError.Or[Unit]]
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

    override def getRecipe(id: UUID @@ RecipeId): Future[Option[Recipe]] = db.run(companion.getRecipe(id))

    override def createRecipe(recipeCreation: RecipeCreation): Future[Recipe] =
      db.run(companion.createRecipe(recipeCreation))

    override def updateRecipe(recipeUpdate: RecipeUpdate): Future[Recipe] = db.run(companion.updateRecipe(recipeUpdate))

    override def deleteRecipe(id: UUID @@ RecipeId): Future[Or[Unit]] = db.run(companion.deleteRecipe(id))

    override def addIngredient(addIngredient: AddIngredient): Future[Or[Unit]] =
      db.run(companion.addIngredient(addIngredient))

    override def removeIngredient(ingredientId: UUID @@ IngredientId): Future[Or[Unit]] =
      db.run(companion.removeIngredient(ingredientId))

    override def updateAmount(ingredientUpdate: IngredientUpdate): Future[Or[Unit]] =
      db.run(companion.updateAmount(ingredientUpdate))

  }

  object Live extends Companion {

    override def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]] =
      Tables.FoodName.result
        .map(_.map(_.transformInto[Food]))

    override def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
      Tables.MeasureName.result
        .map(_.map(_.transformInto[Measure]))

    override def getRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Option[Recipe]] = ???
//      Tables.Recipe.filter(_.id === (id: UUID)).result.headOption

    override def createRecipe(recipeCreation: RecipeCreation)(implicit ec: ExecutionContext): DBIO[Recipe] = ???

    override def updateRecipe(recipeUpdate: RecipeUpdate)(implicit ec: ExecutionContext): DBIO[Recipe] = ???

    override def deleteRecipe(id: UUID @@ RecipeId)(implicit ec: ExecutionContext): DBIO[Or[Unit]] = ???

    override def addIngredient(addIngredient: AddIngredient)(implicit ec: ExecutionContext): DBIO[Or[Unit]] = ???

    override def removeIngredient(ingredientId: UUID @@ IngredientId)(implicit ec: ExecutionContext): DBIO[Or[Unit]] =
      ???

    override def updateAmount(ingredientUpdate: IngredientUpdate)(implicit ec: ExecutionContext): DBIO[Or[Unit]] = ???
  }

}
