package services.complex.ingredient

import enumeratum.EnumEntry
import enumeratum.Enum
import io.scalaland.chimney.Transformer

sealed trait ScalingMode extends EnumEntry

object ScalingMode extends Enum[ScalingMode] {

  case object Recipe extends ScalingMode
  case object Weight extends ScalingMode
  case object Volume extends ScalingMode

  override lazy val values: IndexedSeq[ScalingMode] = findValues

  implicit val toDB: Transformer[ScalingMode, String] =
    _.entryName

  implicit val fromDB: Transformer[String, ScalingMode] =
    withName

}
