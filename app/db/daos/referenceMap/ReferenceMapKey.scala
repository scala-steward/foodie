package db.daos.referenceMap

import db.generated.Tables
import db.{ ReferenceMapId, UserId }
import io.scalaland.chimney.dsl._
import utils.TransformerUtils.Implicits._

case class ReferenceMapKey(
    userId: UserId,
    referenceMapId: ReferenceMapId
)

object ReferenceMapKey {

  def of(row: Tables.ReferenceMapRow): ReferenceMapKey =
    ReferenceMapKey(
      row.userId.transformInto[UserId],
      row.id.transformInto[ReferenceMapId]
    )

}
