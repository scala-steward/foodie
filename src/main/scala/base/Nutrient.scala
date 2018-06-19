package base

sealed trait Nutrient {
  def name: String
}

/* todo: A macro should create the necessary instances from an external source.
         While nutrients should not change on a regular basis,
         it is still more reasonable to stay flexible in this respect.
 */

sealed trait Trace extends Nutrient

object Trace extends NutrientCompanion {

  case object Tryptophane extends Trace {
    override val name: String = "Tryptophane"
  }

  override val all: Traversable[(String, Nutrient)] = Traversable(
    Tryptophane.name -> Tryptophane
  )

}

sealed trait Mineral extends Nutrient

object Mineral extends NutrientCompanion {

  case object Iron extends Mineral {
    override val name: String = "Iron"
  }

  override val all: Traversable[(String, Nutrient)] = Traversable(
    Iron.name -> Iron
  )
}

sealed trait Vitamin extends Nutrient

object Vitamin extends NutrientCompanion {

  case object VitaminC extends Vitamin {
    override val name: String = "Vitamin C"
  }

  override val all: Traversable[(String, Nutrient)] = Traversable(
    VitaminC.name -> VitaminC
  )
}

trait NutrientCompanion {
  def all: Traversable[(String, Nutrient)]

  def find(name: String): Option[Nutrient] = all.collectFirst { case (n, nutrient) if n == name => nutrient }
}

object Nutrient {

  sealed trait Type

  object Type {
    trait MassBased extends Type

    trait IUBased extends Type

    trait EnergyBased extends Type
  }

  def fromString(name: String): Option[Nutrient] = {
    Mineral.find(name)
      .orElse(Vitamin.find(name))
      .orElse(Trace.find(name))
  }
}