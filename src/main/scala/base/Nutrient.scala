package base

sealed trait Nutrient

/* todo: A macro should create the necessary instances from an external source.
         While nutrients should not change on a regular basis,
         it is still more reasonable to stay flexible in this respect.
 */

sealed trait Trace extends Nutrient

object Trace {

  case object Tryptophane extends Trace

}

sealed trait Mineral extends Nutrient

object Mineral {

  case object Iron extends Mineral

}

sealed trait Vitamin extends Nutrient

object Vitamin {

  case object VitaminC extends Vitamin

}

object Nutrient {
  sealed trait Type

  trait MassBased extends Type
  trait IUBased extends Type
  trait EnergyBased extends Type
}