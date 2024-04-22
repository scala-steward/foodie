package services.profile

import db.generated.Tables
import db.{ ProfileId, UserId }
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.syntax._
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Profile(
    id: ProfileId,
    name: String
)

object Profile {

  implicit val fromDB: Transformer[Tables.ProfileRow, Profile] =
    Transformer
      .define[Tables.ProfileRow, Profile]
      .buildTransformer

  case class TransformableToDB(
      userId: UserId,
      profile: Profile
  )

  implicit val toDB: Transformer[TransformableToDB, Tables.ProfileRow] = { transformableToDB =>
    Tables.ProfileRow(
      id = transformableToDB.profile.id.transformInto[UUID],
      userId = transformableToDB.userId.transformInto[UUID],
      name = transformableToDB.profile.name
    )
  }

}
