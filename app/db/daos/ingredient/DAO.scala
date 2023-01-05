package db.daos.ingredient

import db.generated.Tables
import db.{ DAOActions, IngredientId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.RecipeIngredientRow, Tables.RecipeIngredient, IngredientId]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.RecipeIngredientRow, Tables.RecipeIngredient, IngredientId](
      Tables.RecipeIngredient,
      (table, key) => table.id === key.transformInto[UUID]
    ) with DAO

}
