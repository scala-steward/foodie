package services.recipe

import db.generated.Tables
import io.scalaland.chimney.dsl._
import services.{ DBTestUtil, UserId }
import slick.jdbc.PostgresProfile.api._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

object ServiceFunctions {

  def create(
      userId: UserId,
      recipe: Recipe
  ): Future[Unit] =
    createFull(
      userId,
      FullRecipe(
        recipe = recipe,
        ingredients = List.empty
      )
    )

  def createFull(
      userId: UserId,
      fullRecipe: FullRecipe
  ): Future[Unit] = {
    val action = for {
      _ <- Tables.Recipe += (fullRecipe.recipe, userId).transformInto[Tables.RecipeRow]
      _ <- Tables.RecipeIngredient ++= fullRecipe.ingredients.map(i =>
        (i, fullRecipe.recipe.id).transformInto[Tables.RecipeIngredientRow]
      )
    } yield ()

    DBTestUtil
      .dbRun(action)
  }

  def createAll(
      userId: UserId,
      recipes: List[Recipe]
  ): Future[Unit] =
    createAllFull(
      userId,
      recipes.map(FullRecipe(_, List.empty))
    )

  def createAllFull(
      userId: UserId,
      fullRecipes: List[FullRecipe]
  ): Future[Unit] = {
    val action = for {
      _ <- Tables.Recipe ++= fullRecipes.map(fr => (fr.recipe, userId).transformInto[Tables.RecipeRow])
      _ <-
        Tables.RecipeIngredient ++= fullRecipes
          .flatMap { fullRecipe =>
            fullRecipe.ingredients
              .map(i => (i, fullRecipe.recipe.id).transformInto[Tables.RecipeIngredientRow])
          }
    } yield ()

    DBTestUtil
      .dbRun(action)
  }

}
