package services.recipe

import db.FoodId
import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class Food(
    id: FoodId,
    name: String,
    measures: List[Measure]
)

object Food {

  implicit val fromDB: Transformer[(Tables.FoodNameRow, List[Tables.MeasureNameRow]), Food] = {
    case (foodNameRow, measureRows) =>
      Food(
        id = foodNameRow.foodId.transformInto[FoodId],
        name = foodNameRow.foodDescription,
        measures = measureRows.map(_.transformInto[Measure])
      )
  }

}
