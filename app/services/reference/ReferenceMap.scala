package services.reference

import db.generated.Tables
import db.{ ReferenceMapId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class ReferenceMap(
    id: ReferenceMapId,
    name: String
)

object ReferenceMap {

  implicit val fromDB: Transformer[Tables.ReferenceMapRow, ReferenceMap] =
    Transformer
      .define[Tables.ReferenceMapRow, ReferenceMap]
      .buildTransformer

  case class TransformableToDB(
      userId: UserId,
      referenceMap: ReferenceMap
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.ReferenceMapRow] = { transformableToDB =>
    Tables.ReferenceMapRow(
      id = transformableToDB.referenceMap.id.transformInto[UUID],
      userId = transformableToDB.userId.transformInto[UUID],
      name = transformableToDB.referenceMap.name
    )
  }

}
