package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import shapeless.tag.@@

import java.util.UUID

case class Ingredient(
    id: UUID @@ IngredientId,
    foodId: Int @@ FoodId,
    amount: Amount
)

object Ingredient {
  implicit val toDB: Transformer[Ingredient, Tables.RecipeIngredientRow] = ???

}
