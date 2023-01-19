package services.reference

import db.{ NutrientCode, ReferenceMapId }
import io.scalaland.chimney.dsl._
import org.scalacheck.Gen
import services.GenUtils
import spire.math.Natural
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

  def referenceMapUpdateGen(referenceMapId: ReferenceMapId): Gen[ReferenceMapUpdate] =
    for {
      name <- GenUtils.nonEmptyAsciiString
    } yield ReferenceMapUpdate(
      referenceMapId,
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

  def fullReferenceMapGen(maxNumberOfReferenceEntries: Natural = Natural(20)): Gen[FullReferenceMap] =
    for {
      referenceMap     <- referenceMapGen
      referenceEntries <- GenUtils.nonEmptyListOfAtMost(maxNumberOfReferenceEntries, referenceEntryGen)
    } yield FullReferenceMap(
      referenceMap = referenceMap,
      referenceEntries = referenceEntries.toList
    )

  def referenceEntryUpdateGen(referenceMapId: ReferenceMapId, nutrientCode: NutrientCode): Gen[ReferenceEntryUpdate] = {
    GenUtils.smallBigDecimalGen.map(ReferenceEntryUpdate(referenceMapId, nutrientCode = nutrientCode, _))
  }

}
