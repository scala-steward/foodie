package services.stats

import cats.syntax.traverse._
import db.generated.Tables
import io.scalaland.chimney.dsl.TransformerOps
import play.api.db.slick.{ DatabaseConfigProvider, HasDatabaseConfigProvider }
import services.meal.MealService
import services.nutrient.{ NutrientMap, NutrientService }
import services.recipe.RecipeService
import services.{ MealId, RecipeId, UserId }
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._
import spire.implicits._
import utils.DBIOUtil
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import javax.inject.Inject
import scala.concurrent.{ ExecutionContext, Future }

trait StatsService {

  def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats]

}

object StatsService {

  class Live @Inject() (
      override protected val dbConfigProvider: DatabaseConfigProvider,
      companion: Companion
  )(implicit
      ec: ExecutionContext
  ) extends StatsService
      with HasDatabaseConfigProvider[PostgresProfile] {

    override def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval): Future[Stats] =
      db.run(companion.nutrientsOverTime(userId, requestInterval))

  }

  trait Companion {
    def nutrientsOverTime(userId: UserId, requestInterval: RequestInterval)(implicit ec: ExecutionContext): DBIO[Stats]
  }

  object Live extends Companion {

    override def nutrientsOverTime(
        userId: UserId,
        requestInterval: RequestInterval
    )(implicit
        ec: ExecutionContext
    ): DBIO[Stats] = {
      val dateFilter = DBIOUtil.dateFilter(requestInterval.from, requestInterval.to)
      for {
        mealIdsPlain <- Tables.Meal.filter(m => dateFilter(m.consumedOnDate)).map(_.id).result
        mealIds = mealIdsPlain.map(_.transformInto[MealId])
        meals <- mealIds.traverse(MealService.Live.getMeal(userId, _)).map(_.flatten)
        recipes <-
          meals
            .flatMap(_.entries.map(_.recipeId))
            .distinct
            .traverse(RecipeService.Live.getRecipe(userId, _))
            .map(_.flatten)
        nutrientsPerRecipe <-
          recipes
            .traverse(r =>
              NutrientService.Live
                .nutrientsOfIngredients(r.ingredients)
                .map(r.recipeInfo.id -> _): DBIO[(RecipeId, NutrientMap)]
            )
            .map(_.toMap)
      } yield {
        val dailyNutrients = meals
          .groupBy(_.date.date)
          .values
          .map(
            _.flatMap(_.entries)
              .map(me => me.factor *: nutrientsPerRecipe(me.recipeId))
              .qsum
          )

        Stats(
          dailyNutrients = dailyNutrients
        )
      }
    }

  }

}
