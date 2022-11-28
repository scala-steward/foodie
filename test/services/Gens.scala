package services

import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import security.Hash
import services.user.User
import spire.math.Natural
import utils.TransformerUtils.Implicits._
import utils.date.{ Date, SimpleDate, Time }

import java.util.Calendar

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

  def optionalOneOf[A](seq: Seq[A]): Gen[Option[A]] =
    if (seq.isEmpty)
      Gen.const(None)
    else Gen.option(Gen.oneOf(seq))

  def listOfAtMost[A](n: Natural, gen: Gen[A]): Gen[List[A]] =
    Gen
      .choose(0, n.intValue)
      .flatMap(Gen.listOfN(_, gen))

  val timeGen: Gen[Time] = for {
    hour   <- Gen.choose(0, 23)
    minute <- Gen.choose(0, 59)
  } yield Time(
    hour = hour,
    minute = minute
  )

  val dateGen: Gen[Date] = Gen.calendar.map(c =>
    Date(
      year = c.get(Calendar.YEAR),
      month = c.get(Calendar.MONTH),
      day = c.get(Calendar.DAY_OF_MONTH)
    )
  )

  val simpleDateGen: Gen[SimpleDate] = for {
    date <- dateGen
    time <- Gen.option(timeGen)
  } yield SimpleDate(
    date = date,
    time = time
  )

}
