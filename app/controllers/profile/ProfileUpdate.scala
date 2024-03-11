package controllers.profile

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec(decodeOnly = true)
case class ProfileUpdate(
    name: String
)

object ProfileUpdate {

  implicit val toInternal: Transformer[ProfileUpdate, services.profile.ProfileUpdate] =
    Transformer
      .define[ProfileUpdate, services.profile.ProfileUpdate]
      .buildTransformer

}
