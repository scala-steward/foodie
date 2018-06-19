package db

import amounts.Palette
import base.Nutrient.{EnergyBased, IUBased, MassBased}
import base._
import com.mongodb.casbah.commons.MongoDBObject
import com.mongodb.casbah.Imports._
import physical.PUnit.Syntax.{Calorie, Gram, IU}
import physical.{NamedUnit, PUnit, PhysicalAmount, Prefix}
import spire.math.Numeric

object Finder {

  def getNutrientEntries(foodId: Id): Iterator[DbNutrientEntry] = {
    MongoFactory.collection.find(MongoDBObject(DbFoodName.foodIdLabel -> foodId)).flatMap { thing =>
      DbNutrientEntry.Implicits.nutrientEntryFromDB.fromDB(thing)
    }
  }

  def getNutrientData(nutrientId: Id): Option[DbNutrientData] = {
    MongoFactory.collection.findOne(MongoDBObject(DbNutrientData.nutrientId -> nutrientId)).flatMap { thing =>
      DbNutrientData.Implicits.nutrientDataFromDB.fromDB(thing)
    }
  }

  def toNutrientAssociation(nutrientData: DbNutrientData,
                            amount: Floating): Option[(Nutrient, NamedUnit[Floating, _, _])] = {
    def catchType[P, U](prefix: Prefix[P], unit: PUnit[U]): NamedUnit[Floating, P, U] = {
      val physicalAmount = PhysicalAmount.fromRelative(amount)(Numeric[Floating], prefix)
      NamedUnit[Floating, P, U](physicalAmount, unit)
    }

    val nutrientOpt = Nutrient.fromString(nutrientData.name)
    val prefix: Prefix[_] = nutrientData.prefix
    val namedUnit = catchType(prefix, nutrientData.unit)
    nutrientOpt.map(_ -> namedUnit)
  }

  def getPalette(preciseName: String): Option[Palette[Floating]] = {
    val candidate = MongoFactory.collection.findOne(MongoDBObject(DbFoodName.nameLabel -> preciseName))
    for {
      thing <- candidate
      food <- DbFoodName.Implicits.foodNameFromDB.fromDB(thing)
    } yield {
      val nutrientEntries = getNutrientEntries(food.foodId)
      val associations: Iterator[(Nutrient, NamedUnit[Floating, _, _])] = nutrientEntries.flatMap { entry =>
        val nutrientId = entry.nutrientId
        val nutrientDataOpt = getNutrientData(nutrientId)
        nutrientDataOpt.flatMap(toNutrientAssociation(_, entry.amount))
      }

      val (withGram, withIUnit, withEnergy) =
        associations.foldLeft(
          (Seq.empty[(Nutrient with MassBased, Mass[Floating, _])],
            Seq.empty[(Nutrient with IUBased, IUnit[Floating, _])],
            Seq.empty[(Nutrient with EnergyBased, Energy[Floating, _])]
          )
        ) { case ((masses, units, energies), (nutrient, NamedUnit(amount, unit))) =>
            val (newMasses, newUnits, newEnergies) =
              if (unit == Gram){
                val next = nutrient.asInstanceOf[Nutrient with MassBased] -> NamedUnit(amount, Gram)
                (next +: masses, units, energies)
              }
              else if (unit == IU) {
                val next = nutrient.asInstanceOf[Nutrient with IUBased] -> NamedUnit(amount, IU)
                (masses, next +: units, energies)
              }
              else if (unit == Calorie) {
                val next = nutrient.asInstanceOf[Nutrient with EnergyBased] -> NamedUnit(amount, Calorie)
                (masses, units, next +: energies)
              }
              else (masses, units, energies)
          (newMasses, newUnits, newEnergies)
        }

      Palette.fromAssociations(withGram, withIUnit, withEnergy)
    }
  }

}

object TestMe {

  def main(args: Array[String]): Unit = {
    val pal = Finder.getPalette("Avocado, raw, california")
    println(pal)
  }
}