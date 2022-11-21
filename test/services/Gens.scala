package services

import org.scalacheck.Gen
import services.user.User
import utils.TransformerUtils.Implicits._
import io.scalaland.chimney.dsl._
import security.Hash

object Gens {

  val nonEmptyAsciiString: Gen[String] =
    Gen
      .nonEmptyListOf(Gen.asciiPrintableChar)
      .map(_.mkString)

  val userWithFixedPassword: Gen[User] = for {
    id          <- Gen.uuid.map(_.transformInto[UserId])
    nickname    <- nonEmptyAsciiString
    displayName <- Gen.option(nonEmptyAsciiString)
    email       <- nonEmptyAsciiString
    salt        <- Gen.listOfN(40, Gen.alphaNumChar).map(_.mkString)
  } yield User(
    id = id,
    nickname = nickname,
    displayName = displayName,
    email = email,
    salt = salt,
    hash = Hash.fromPassword("password", salt, Hash.defaultIterations)
  )

}
