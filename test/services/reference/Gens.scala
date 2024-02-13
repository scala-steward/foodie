package services.reference

import db.ReferenceMapId
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services.GenUtils
import utils.TransformerUtils.Implicits._

object Gens {

  val referenceMapCreationGen: Gen[ReferenceMapCreation] = for {
    name <- GenUtils.nonEmptyAsciiString
  } yield ReferenceMapCreation(
    name = name
  )

  val referenceMapGen: Gen[ReferenceMap] = for {
    id                   <- Gen.uuid.map(_.transformInto[ReferenceMapId])
    referenceMapCreation <- referenceMapCreationGen
  } yield ReferenceMapCreation.create(id, referenceMapCreation)

  val referenceMapUpdateGen: Gen[ReferenceMapUpdate] =
    for {
      name <- GenUtils.nonEmptyAsciiString
    } yield ReferenceMapUpdate(
      name = name
    )

  val referenceEntryGen: Gen[ReferenceEntry] =
    for {
      nutrient <- GenUtils.nutrientGen
      amount   <- GenUtils.smallBigDecimalGen
    } yield ReferenceEntry(
      nutrientCode = nutrient.code,
      amount = amount
    )

  val fullReferenceMapGen: Gen[FullReferenceMap] =
    for {
      referenceMap     <- referenceMapGen
      referenceEntries <- Gen.nonEmptyListOf(referenceEntryGen)
    } yield FullReferenceMap(
      referenceMap = referenceMap,
      referenceEntries = referenceEntries.distinctBy(_.nutrientCode)
    )

  val referenceEntryUpdateGen: Gen[ReferenceEntryUpdate] = {
    GenUtils.smallBigDecimalGen.map(ReferenceEntryUpdate(_))
  }

}
