package db.daos.complexIngredient

import db.DAOActions
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ComplexIngredientRow, Tables.ComplexIngredient, ComplexIngredientKey]

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ComplexIngredientRow, Tables.ComplexIngredient, ComplexIngredientKey](
      Tables.ComplexIngredient,
      (table, key) =>
        table.recipeId === key.recipeId.transformInto[UUID] &&
          table.complexFoodId === key.complexFoodId.transformInto[UUID],
      ComplexIngredientKey.of
    ) with DAO

}
