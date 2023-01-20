package services.recipe

import db.MeasureId
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class AmountUnit(
    measureId: Option[MeasureId],
    factor: BigDecimal
)

object AmountUnit {
  val hundredGrams: MeasureId = 1455.transformInto[MeasureId]
}
