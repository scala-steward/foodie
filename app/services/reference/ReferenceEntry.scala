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

  case class TransformableToDB(
      userId: UserId,
      referenceMapId: ReferenceMapId,
      referenceEntry: ReferenceEntry
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.ReferenceEntryRow] = { transformableToDB =>
    Tables.ReferenceEntryRow(
      referenceMapId = transformableToDB.referenceMapId.transformInto[UUID],
      nutrientCode = transformableToDB.referenceEntry.nutrientCode.transformInto[Int],
      amount = transformableToDB.referenceEntry.amount,
      userId = transformableToDB.userId.transformInto[UUID]
    )

  }

}
