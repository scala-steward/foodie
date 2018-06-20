package base

sealed trait Type

object Type {
  trait MassBased extends Type

  object MassBased {
    val all: Traversable[Nutrient with MassBased] = Traversable(

    )
  }

  trait IUBased extends Type

  object IUBased {
    val all: Traversable[Nutrient with IUBased] = Traversable(

    )
  }

  trait EnergyBased extends Type

  object EnergyBased {
    val all: Traversable[Nutrient with EnergyBased] = Traversable(

    )
  }
}