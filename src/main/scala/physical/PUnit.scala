package physical

trait PUnit[U] {
  def name: String
  def abbreviation: String
}
//todo: The names should not be fixed by fetched from a file/database.
sealed trait Gram extends PUnit[Gram] {
  override val name: String = "gram"
  override val abbreviation: String = "g"
}

sealed trait Metre extends PUnit[Metre] {
  override val name: String = "meter"
  override val abbreviation: String = "m"
}

sealed trait Litre extends PUnit[Litre] {
  override val name: String = "litre"
  override val abbreviation: String = "l"
}

sealed trait CubicCentimetre extends PUnit[CubicCentimetre] {
  override val name: String = "cubic centimeter"
  override val abbreviation: String = "cm³"
}

object PUnit {

  def apply[U: PUnit]: PUnit[U] = implicitly[PUnit[U]]

  object Syntax extends Syntax

  trait Syntax {
    implicit case object Gram extends Gram
    implicit case object Metre extends Metre
    implicit case object Litre extends Litre
    implicit case object CubicCentimetre extends CubicCentimetre
  }
}