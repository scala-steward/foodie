package db.daos.complexFood

import db.{ DAOActions, RecipeId }
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ComplexFoodRow, Tables.ComplexFood, RecipeId]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ComplexFoodRow, Tables.ComplexFood, RecipeId](
      Tables.ComplexFood,
      (table, key) => table.recipeId === key.transformInto[UUID],
      _.recipeId.transformInto[RecipeId]
    ) with DAO

}
