package services.recipe

import db.FoodId
import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class FoodInfo(
    id: FoodId,
    name: String
)

object FoodInfo {

  implicit val fromDB: Transformer[Tables.FoodNameRow, FoodInfo] = row =>
    FoodInfo(
      id = row.foodId.transformInto[FoodId],
      name = row.foodDescription
    )

}
