package db.daos.meal

import db.generated.Tables
import db.{ DAOActions, UserId }
import io.scalaland.chimney.dsl._
import services.common.RequestInterval
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.MealRow, MealKey] {
  def allInInterval(userId: UserId, requestInterval: RequestInterval): DBIO[Seq[Tables.MealRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealRow, Tables.Meal, MealKey](
      Tables.Meal,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.mealId.transformInto[UUID],
      MealKey.of
    ) with DAO {

      override def allInInterval(
          userId: UserId,
          requestInterval: RequestInterval
      ): DBIO[Seq[Tables.MealRow]] = {
        val dateFilter: Rep[java.sql.Date] => Rep[Boolean] =
          DBIOUtil.dateFilter(requestInterval.from, requestInterval.to)

        Tables.Meal
          .filter(meal =>
            meal.userId === userId.transformInto[UUID] &&
              dateFilter(meal.consumedOnDate)
          )
          .result
      }

    }

}
