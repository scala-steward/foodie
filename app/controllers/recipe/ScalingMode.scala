package controllers.recipe

import enumeratum.{ CirceEnum, Enum, EnumEntry }
import io.scalaland.chimney.Transformer

sealed trait ScalingMode extends EnumEntry

object ScalingMode extends Enum[ScalingMode] with CirceEnum[ScalingMode] {

  case object Recipe extends ScalingMode
  case object Weight extends ScalingMode
  case object Volume extends ScalingMode

  override lazy val values: IndexedSeq[ScalingMode] = findValues

  implicit val toInternal: Transformer[ScalingMode, services.complex.ingredient.ScalingMode] = {
    case Recipe => services.complex.ingredient.ScalingMode.Recipe
    case Weight => services.complex.ingredient.ScalingMode.Weight
    case Volume => services.complex.ingredient.ScalingMode.Volume
  }

  implicit val fromInternal: Transformer[services.complex.ingredient.ScalingMode, ScalingMode] = {
    case services.complex.ingredient.ScalingMode.Recipe => Recipe
    case services.complex.ingredient.ScalingMode.Weight => Weight
    case services.complex.ingredient.ScalingMode.Volume => Volume
  }

}
