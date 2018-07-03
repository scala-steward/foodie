package db.cnf


import com.github.tototoshi.csv.CSVReader
import com.mongodb.casbah.Imports._
import db._
import physical.PUnit

import scala.util.Try

object FromDB {

  private def readWith[A](parser: Seq[String] => Option[A])(file: String): List[A] = {
    val reader = CSVReader.open(file, encoding = "ISO-8859-1")
    val fileLines = reader.iterator.drop(1)
    val keyValues = fileLines.flatMap(cells => parser(cells))
    keyValues.toList
  }

  private def readNutrientData: String => List[DbNutrientData] = {
    readWith { cells =>
      for {
        (id, name, prefixAndUnit) <- Try(
          cells(Locations.NutrientName.id).toInt,
          cells(Locations.NutrientName.name),
          cells(Locations.NutrientName.prefixedUnit)
        ).toOption
        (prefix, unit) <- PUnit.bothFromAbbreviation(prefixAndUnit)
      } yield DbNutrientData(id, name, unit, prefix)
    }
  }

  private def readNutrientAmounts: String => List[DbNutrientEntry] = {
    readWith { cells =>
      Try(
        cells(Locations.NutrientAmount.foodId).toInt,
        cells(Locations.NutrientAmount.nutrientId).toInt,
        cells(Locations.NutrientAmount.nutrientAmount).toDouble,
        cells(Locations.NutrientAmount.nutrientSource)
      ).map {
        case (foodId, nutrientId, nutrientAmount, nutrientSource) =>
          val entry = DbNutrientEntry(foodId, nutrientAmount, nutrientId, nutrientSource)
          entry
      }.toOption
    }
  }

  private def readNutrientSources: String => List[DbNutrientSource] = {
    readWith { cells =>
      Try(
        cells(Locations.NutrientSource.nutrientId).toInt,
        cells(Locations.NutrientSource.nutrientSource)
      ).map {
        case (nutrientId, source) => DbNutrientSource(nutrientId, source)
      }.toOption
    }
  }

  private def readFoodNames: String => List[DbFoodName] = {
    readWith { cells =>
      Try(
        cells(Locations.FoodName.foodId).toInt,
        cells(Locations.FoodName.foodName)
      ).map { case (foodId, foodName) =>
        DbFoodName(foodId, foodName)
      }.toOption
    }
  }

  private def readConversionFactors: String => List[DbConversionFactor] = {
    readWith { cells =>
      Try(
        cells(Locations.ConversionFactor.foodId).toInt,
        cells(Locations.ConversionFactor.measureId).toInt,
        cells(Locations.ConversionFactor.factor).toDouble
      ).map { case (foodId, measureId, factor) =>
          DbConversionFactor(foodId, measureId, factor)
      }.toOption
    }
  }

  private def readMeasureNames: String => List[DbMeasureName] = {
    readWith { cells =>
      Try(
        cells(Locations.MeasureName.measureId).toInt,
        cells(Locations.MeasureName.name)
      ).map { case (measureId, name) =>
        DbMeasureName(measureId, name)
      }.toOption
    }
  }

  private def readAndInsert[A <: ToMongoDBObject](parser: String => List[A])(original: String): Unit = {
    val result = parser(original)
    result.foreach { x =>
      MongoFactory.collection.save(x.db)
    }
  }

  def main(args: Array[String]): Unit = {
//    readAndInsert(readNutrientData)(Locations.NutrientName.location)
//    readAndInsert(readNutrientAmounts)(Locations.NutrientAmount.location)
//    readAndInsert(readNutrientSources)(Locations.NutrientSource.location)
//    readAndInsert(readFoodNames)(Locations.FoodName.location)
//    readAndInsert(readConversionFactors)(Locations.ConversionFactor.location)
    readAndInsert(readMeasureNames)(Locations.MeasureName.location)
  }

}
