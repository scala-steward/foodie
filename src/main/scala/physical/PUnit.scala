package physical

trait PUnit {
  def name: String
  def abbreviation: String
}
//todo: The names should not be fixed by fetched from a file/database.
sealed trait Gram extends PUnit {
  override val name: String = "gram"
  override val abbreviation: String = "g"
}

sealed trait Metre extends PUnit {
  override val name: String = "meter"
  override val abbreviation: String = "m"
}

sealed trait Litre extends PUnit {
  override val name: String = "litre"
  override val abbreviation: String = "l"
}

sealed trait CubicCentimetre extends PUnit {
  override val name: String = "cubic centimeter"
  override val abbreviation: String = "cm³"
}

object PUnit {
  object Syntax extends Syntax

  trait Syntax {
    case object Gram extends Gram
    case object Metre extends Metre
    case object Litre extends Litre
    case object CubicCentimetre extends CubicCentimetre
  }
}