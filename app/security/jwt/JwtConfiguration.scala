package security.jwt

case class JwtConfiguration(
    signaturePublicKey: String,
    signaturePrivateKey: String,
    restrictedDurationInSeconds: Long
)
