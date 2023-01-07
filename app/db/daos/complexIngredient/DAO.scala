package db.daos.complexIngredient

import db.generated.Tables
import db.{ DAOActions, RecipeId }
import io.scalaland.chimney.dsl._
import slick.jdbc.PostgresProfile.api._
import utils.TransformerUtils.Implicits._

import java.util.UUID

trait DAO extends DAOActions[Tables.ComplexIngredientRow, ComplexIngredientKey] {
  def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.ComplexIngredientRow]]
}

object DAO {

  val instance: DAO =
    new DAOActions.Instance[Tables.ComplexIngredientRow, Tables.ComplexIngredient, ComplexIngredientKey](
      Tables.ComplexIngredient,
      (table, key) =>
        table.recipeId === key.recipeId.transformInto[UUID] &&
          table.complexFoodId === key.complexFoodId.transformInto[UUID],
      ComplexIngredientKey.of
    ) with DAO {

      override def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.ComplexIngredientRow]] =
        Tables.ComplexIngredient
          .filter(_.recipeId === recipeId.transformInto[UUID])
          .result

    }

}
