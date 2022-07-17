package services.recipe

import db.generated.Tables
import io.scalaland.chimney.Transformer
import shapeless.tag.@@
import utils.IdUtils.Implicits._

case class Measure(
    id: Int @@ MeasureId,
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
