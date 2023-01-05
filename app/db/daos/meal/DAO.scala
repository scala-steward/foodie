package db.daos.meal

import db.DAOActions
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.MealRow, Tables.Meal, MealKey]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.MealRow, Tables.Meal, MealKey](
      Tables.Meal,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.mealId.transformInto[UUID],
      MealKey.of
    ) with DAO

}
