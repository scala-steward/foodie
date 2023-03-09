package db.daos.recipe

import db.generated.Tables
import db.{ DAOActions, RecipeId, UserId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.RecipeRow, RecipeKey] {

  override val keyOf: Tables.RecipeRow => RecipeKey = RecipeKey.of

  def findAllFor(userId: UserId): DBIO[Seq[Tables.RecipeRow]]

  def allOf(userId: UserId, ids: Seq[RecipeId]): DBIO[Seq[Tables.RecipeRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.RecipeRow, Tables.Recipe, RecipeKey](
      Tables.Recipe,
      (table, key) => table.userId === key.userId.transformInto[UUID] && table.id === key.recipeId.transformInto[UUID]
    ) with DAO {

      override def findAllFor(userId: UserId): DBIO[Seq[Tables.RecipeRow]] =
        Tables.Recipe
          .filter(
            _.userId === userId.transformInto[UUID]
          )
          .result

      override def allOf(userId: UserId, ids: Seq[RecipeId]): DBIO[Seq[Tables.RecipeRow]] = {
        val untypedIds = ids.distinct.map(_.transformInto[UUID])
        Tables.Recipe
          .filter(recipe => recipe.userId === userId.transformInto[UUID] && recipe.id.inSetBind(untypedIds))
          .result
      }

    }

}
