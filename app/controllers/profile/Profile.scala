package controllers.profile

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

import java.util.UUID

@JsonCodec(encodeOnly = true)
case class Profile(
    id: UUID,
    name: String
)

object Profile {

  implicit val fromInternal: Transformer[services.profile.Profile, Profile] =
    Transformer
      .define[services.profile.Profile, Profile]
      .buildTransformer

}
