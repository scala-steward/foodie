package db

import amounts.Palette
import base._
import com.mongodb.casbah.commons.MongoDBObject
import com.mongodb.casbah.Imports._
import physical.PUnit.Syntax.Gram
import physical.{NamedUnit, PUnit, PhysicalAmount, Prefix}
import spire.math.Numeric

object Finder {

  def nutrientByName(name: String): Nutrient = ???

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
                            amount: Floating): (Nutrient, NamedUnit[Floating, _, _]) = {
    def catchType[P, U](prefix: Prefix[P], unit: PUnit[U]): NamedUnit[Floating, P, U] = {
      val physicalAmount = PhysicalAmount.fromRelative(amount)(Numeric[Floating], prefix)
      NamedUnit[Floating, P, U](physicalAmount, unit)
    }

    val nutrient = nutrientByName(nutrientData.name)
    val prefix: Prefix[_] = nutrientData.prefix
    val namedUnit = catchType(prefix, nutrientData.unit)
    nutrient -> namedUnit
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
        nutrientDataOpt.map(toNutrientAssociation(_, entry.amount))
      }

      val withGram = associations.collect {
        case a@(_, namedUnit) if namedUnit.unit == Gram => a
      }

//      Functional.fromAssociations(???)
    }
    ???
  }

}
