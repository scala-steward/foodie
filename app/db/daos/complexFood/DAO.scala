package db.daos.complexFood

import db.{ DAOActions, RecipeId, UserId }
import db.generated.Tables
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ComplexFoodRow, ComplexFoodKey] {

  override val keyOf: Tables.ComplexFoodRow => ComplexFoodKey = ComplexFoodKey.of

  def allOf(userId: UserId, ids: Seq[RecipeId]): DBIO[Seq[Tables.ComplexFoodRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ComplexFoodRow, Tables.ComplexFood, ComplexFoodKey](
      Tables.ComplexFood,
      (table, key) =>
        table.userId === key.userId.transformInto[UUID] && table.recipeId === key.recipeId.transformInto[UUID]
    ) with DAO {

      override def allOf(userId: UserId, ids: Seq[RecipeId]): DBIO[Seq[Tables.ComplexFoodRow]] = {
        val untypedIds = ids.distinct.map(_.transformInto[UUID])
        Tables.ComplexFood
          .filter(complexFood =>
            complexFood.userId === userId.transformInto[UUID] && complexFood.recipeId.inSetBind(untypedIds)
          )
          .result
      }

    }

}
