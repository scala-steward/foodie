package controllers.profile

import io.circe.generic.JsonCodec
import io.scalaland.chimney.Transformer

@JsonCodec(decodeOnly = true)
case class ProfileCreation(
    name: String
)

object ProfileCreation {

  implicit val toInternal: Transformer[ProfileCreation, services.profile.ProfileCreation] =
    Transformer
      .define[ProfileCreation, services.profile.ProfileCreation]
      .buildTransformer

}
