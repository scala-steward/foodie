package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import services.FoodId
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
