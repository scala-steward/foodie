package security.jwt

import pureconfig.generic.ProductHint
import pureconfig.{ CamelCase, ConfigFieldMapping, ConfigSource }
import pureconfig.generic.auto._

case class JwtConfiguration(
    signaturePublicKey: String,
    signaturePrivateKey: String,
    restrictedDurationInSeconds: Long
)

object JwtConfiguration {

  implicit def hint[A]: ProductHint[A] = ProductHint[A](ConfigFieldMapping(CamelCase, CamelCase))

  val default: JwtConfiguration = ConfigSource.default
    .at("jwtConfiguration")
    .loadOrThrow[JwtConfiguration]

}
