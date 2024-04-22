package db.daos.profile

import db.generated.Tables
import db.{ ProfileId, UserId }
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

case class ProfileKey(
    userId: UserId,
    profileId: ProfileId
)

object ProfileKey {

  def of(row: Tables.ProfileRow): ProfileKey =
    ProfileKey(
      row.userId.transformInto[UserId],
      row.id.transformInto[ProfileId]
    )

}
