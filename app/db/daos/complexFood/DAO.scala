package db.daos.complexFood

import db.generated.Tables
import db.{ DAOActions, RecipeId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ComplexFoodRow, RecipeId] {

  override val keyOf: Tables.ComplexFoodRow => RecipeId = _.recipeId.transformInto[RecipeId]

  def findByKeys(keys: Seq[RecipeId]): DBIO[Seq[Tables.ComplexFoodRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ComplexFoodRow, Tables.ComplexFood, RecipeId](
      Tables.ComplexFood,
      (table, key) => table.recipeId === key.transformInto[UUID]
    ) with DAO {

      override def findByKeys(keys: Seq[RecipeId]): DBIO[Seq[Tables.ComplexFoodRow]] = {
        val untypedIds = keys.distinct.map(_.transformInto[UUID])
        Tables.ComplexFood
          .filter(_.recipeId.inSetBind(untypedIds))
          .result
      }

    }

}
