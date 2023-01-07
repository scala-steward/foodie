package db.daos.ingredient

import db.generated.Tables
import db.{ DAOActions, IngredientId, RecipeId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.RecipeIngredientRow, IngredientId] {
  def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.RecipeIngredientRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.RecipeIngredientRow, Tables.RecipeIngredient, IngredientId](
      Tables.RecipeIngredient,
      (table, key) => table.id === key.transformInto[UUID],
      _.id.transformInto[IngredientId]
    ) with DAO {

      override def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.RecipeIngredientRow]] =
        Tables.RecipeIngredient
          .filter(_.recipeId === recipeId.transformInto[UUID])
          .result

    }

}
