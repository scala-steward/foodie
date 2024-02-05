package services.reference

import db.generated.Tables
import db.{ NutrientCode, ReferenceMapId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ReferenceEntry(
    nutrientCode: NutrientCode,
    amount: BigDecimal
)

object ReferenceEntry {

  implicit val fromDB: Transformer[Tables.ReferenceEntryRow, ReferenceEntry] =
    Transformer
      .define[Tables.ReferenceEntryRow, ReferenceEntry]
      .buildTransformer

  implicit val toDB: Transformer[(ReferenceEntry, ReferenceMapId, UserId), Tables.ReferenceEntryRow] = {
    case (referenceEntry, referenceMapId, userId) =>
      Tables.ReferenceEntryRow(
        referenceMapId = referenceMapId.transformInto[UUID],
        nutrientCode = referenceEntry.nutrientCode.transformInto[Int],
        amount = referenceEntry.amount,
        userId = userId.transformInto[UUID]
      )

  }

}
