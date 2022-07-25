package services.nutrient

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import spire.math.Natural
import utils.TransformerUtils.Implicits._

import scala.util.Try
import scala.util.chaining._

case class Nutrient(
    id: NutrientId,
    code: NutrientCode,
    symbol: String,
    unit: NutrientUnit,
    name: String,
    nameFrench: String,
    tagName: Option[String],
    decimals: Natural
)

object Nutrient {

  implicit val fromDB: Transformer[Tables.NutrientNameRow, Nutrient] = row =>
    Nutrient(
      id = row.nutrientNameId.transformInto[NutrientId],
      code = row.nutrientCode.transformInto[NutrientCode],
      symbol = row.nutrientSymbol,
      unit = row.nutrientUnit.pipe(NutrientUnit.withName),
      name = row.nutrientName,
      nameFrench = row.nutrientNameF,
      tagName = row.tagname,
      decimals = Try(Natural(row.nutrientDecimals)).getOrElse(Natural.zero)
    )

}
