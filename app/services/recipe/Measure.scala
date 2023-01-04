package services.recipe

import db.generated.Tables
import db.MeasureId
import io.scalaland.chimney.Transformer
import utils.TransformerUtils.Implicits._

case class Measure(
    id: MeasureId,
    name: String
)

object Measure {

  implicit val fromDB: Transformer[Tables.MeasureNameRow, Measure] =
    Transformer
      .define[Tables.MeasureNameRow, Measure]
      .withFieldRenamed(_.measureId, _.id)
      .withFieldRenamed(_.measureDescription, _.name)
      .buildTransformer

}
