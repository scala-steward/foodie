package services.stats

import cats.data.EitherT
import cats.instances.list._
import cats.syntax.traverse._
import db.generated.Tables
import org.scalacheck.{ Prop, Properties }
import play.api.db.slick.DatabaseConfigProvider
import play.api.inject.guice.GuiceApplicationBuilder
import services.Gens
import services.recipe.RecipeService
import services.user.UserService
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._

import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.Duration

object RecipeStatsProperties extends Properties("Recipe stats") {

  private val injector = GuiceApplicationBuilder()
    .build()
    .injector

  private val recipeService = injector
    .instanceOf[RecipeService]

  private val userService = injector
    .instanceOf[UserService]

  private val databaseConfigProvider = injector.instanceOf[DatabaseConfigProvider]

  // TODO: Rename
  property("First property") = Prop.forAll(
    Gens.userWithFixedPassword :| "User",
    StatsGens.recipeParametersGen :| "Recipe parameters"
  ) { (user, recipeParameters) =>
    // TODO: Extract this function
    Await.result(
      databaseConfigProvider
        .get[PostgresProfile]
        .db
        .run(
          DBIO.seq(
            Tables.Recipe.delete,
            Tables.User.delete
          )
        ),
      Duration.Inf
    )
    val transformer = for {
      _      <- EitherT.liftF(userService.add(user))
      recipe <- EitherT(recipeService.createRecipe(user.id, recipeParameters.recipeCreation))
      ingredients <- recipeParameters.ingredientParameters.toList.traverse(ip =>
        EitherT(recipeService.addIngredient(user.id, ip.ingredientCreation(recipe.id)))
      )
    } yield {
      // TODO: Add more sensible properties
      ingredients.length == recipeParameters.ingredientParameters.length
    }

    Await.result(
      transformer.fold(
        error => {
          pprint.log(error.message)
          false
        },
        identity
      ),
      Duration.Inf
    )
  }
}
