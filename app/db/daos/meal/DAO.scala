package db.daos.meal

import db.generated.Tables
import db.{ DAOActions, MealId, ProfileId, UserId }
import io.scalaland.chimney.dsl._
import services.common.RequestInterval
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.MealRow, MealKey] {

  override val keyOf: Tables.MealRow => MealKey = MealKey.of

  def allInInterval(userId: UserId, profileId: ProfileId, requestInterval: RequestInterval): DBIO[Seq[Tables.MealRow]]

  def allOf(userId: UserId, mealIds: Seq[MealId]): DBIO[Seq[Tables.MealRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealRow, Tables.Meal, MealKey](
      Tables.Meal,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.mealId.transformInto[UUID]
    ) with DAO {

      override def allInInterval(
          userId: UserId,
          profileId: ProfileId,
          requestInterval: RequestInterval
      ): DBIO[Seq[Tables.MealRow]] = {
        val dateFilter: Rep[java.sql.Date] => Rep[Boolean] =
          DBIOUtil.dateFilter(requestInterval.from, requestInterval.to)

        Tables.Meal
          .filter(meal =>
            meal.userId === userId.transformInto[UUID] &&
              meal.profileId === profileId.transformInto[UUID] &&
              dateFilter(meal.consumedOnDate)
          )
          .result
      }

      override def allOf(userId: UserId, mealIds: Seq[MealId]): DBIO[Seq[Tables.MealRow]] = {
        val untypedIds = mealIds.distinct.map(_.transformInto[UUID])
        Tables.Meal
          .filter(meal => meal.userId === userId.transformInto[UUID] && meal.id.inSetBind(untypedIds))
          .result
      }

    }

}
