package computation.physical

trait PUnit[U] {
  def name: String
  def abbreviation: String
}

//todo: The names should not be fixed but fetched from a file/database.
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

sealed trait Joule extends PUnit[Joule] {
  override val name: String = "Joule"
  override val abbreviation: String = "J"
}

sealed trait Calorie extends PUnit[Calorie] {
  override val name: String = "Calorie"
  override val abbreviation: String = "Cal"
}

sealed trait IU extends PUnit[IU] {
  override val name: String = "International Unit"
  override def abbreviation: String = "IU"
}

object PUnit {

  def apply[U: PUnit]: PUnit[U] = implicitly[PUnit[U]]

  object Syntax extends Syntax

  trait Syntax {
    implicit case object Gram extends Gram
    implicit case object Metre extends Metre
    implicit case object Litre extends Litre
    implicit case object CubicCentimetre extends CubicCentimetre
    implicit case object Joule extends Joule
    implicit case object Calorie extends Calorie
    implicit case object IU extends IU
  }
}