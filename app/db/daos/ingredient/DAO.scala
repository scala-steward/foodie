package db.daos.ingredient

import db.generated.Tables
import db.{ DAOActions, RecipeId, UserId }
import io.scalaland.chimney.syntax._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.RecipeIngredientRow, IngredientKey] {

  override val keyOf: Tables.RecipeIngredientRow => IngredientKey = IngredientKey.of

  def findAllFor(userId: UserId, recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.RecipeIngredientRow]]

}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.RecipeIngredientRow, Tables.RecipeIngredient, IngredientKey](
      Tables.RecipeIngredient,
      (table, key) =>
        table.userId === key.userId.transformInto[UUID] &&
          table.recipeId === key.recipeId.transformInto[UUID] &&
          table.id === key.ingredientId.transformInto[UUID]
    ) with DAO {

      override def findAllFor(userId: UserId, recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.RecipeIngredientRow]] = {
        val untypedIds = recipeIds.distinct.map(_.transformInto[UUID])
        Tables.RecipeIngredient
          .filter(ingredient =>
            ingredient.userId === userId.transformInto[UUID] && ingredient.recipeId.inSetBind(untypedIds)
          )
          .result
      }

    }

}
