package db.daos.ingredient

import db.generated.Tables
import db.{ DAOActions, IngredientId, RecipeId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.RecipeIngredientRow, IngredientId] {

  override val keyOf: Tables.RecipeIngredientRow => IngredientId = _.id.transformInto[IngredientId]

  def findAllFor(recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.RecipeIngredientRow]]

}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.RecipeIngredientRow, Tables.RecipeIngredient, IngredientId](
      Tables.RecipeIngredient,
      (table, key) => table.id === key.transformInto[UUID]
    ) with DAO {

      override def findAllFor(recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.RecipeIngredientRow]] = {
        val untypedIds = recipeIds.map(_.transformInto[UUID])
        Tables.RecipeIngredient
          .filter(_.recipeId.inSetBind(untypedIds))
          .result
      }

    }

}
