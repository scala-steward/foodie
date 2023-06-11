package db.daos.complexIngredient

import db.generated.Tables
import db.{ ComplexFoodId, DAOActions, RecipeId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ComplexIngredientRow, ComplexIngredientKey] {

  override val keyOf: Tables.ComplexIngredientRow => ComplexIngredientKey = ComplexIngredientKey.of

  def findAllFor(recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.ComplexIngredientRow]]

  def findReferencing(complexFoodId: ComplexFoodId): DBIO[Seq[Tables.ComplexIngredientRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ComplexIngredientRow, Tables.ComplexIngredient, ComplexIngredientKey](
      Tables.ComplexIngredient,
      (table, key) =>
        table.recipeId === key.recipeId.transformInto[UUID] &&
          table.complexFoodId === key.complexFoodId.transformInto[UUID]
    ) with DAO {

      override def findAllFor(recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.ComplexIngredientRow]] = {
        val untypedIds = recipeIds.distinct.map(_.transformInto[UUID])
        Tables.ComplexIngredient
          .filter(_.recipeId.inSetBind(untypedIds))
          .result
      }

      override def findReferencing(complexFoodId: ComplexFoodId): DBIO[Seq[Tables.ComplexIngredientRow]] = {
        val untypedId = complexFoodId.transformInto[UUID]
        Tables.ComplexIngredient
          .filter(_.complexFoodId === untypedId)
          .result
      }

    }

}
