package db.cnf


import java.text.SimpleDateFormat

import com.github.tototoshi.csv.CSVReader
import com.mongodb.casbah.Imports._
import db._
import physical.PUnit

import scala.util.Try

object FromDB {

  type Id = Int

  private def readWith[A](parser: Seq[String] => Option[A])(file: String): List[A] = {
    val reader = CSVReader.open(file)
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
        (prefix, unit) <- PUnit.fromAbbreviation(prefixAndUnit)
      } yield DbNutrientData(id, name, unit, prefix)
    }
  }

  private def readNutrientAmounts: String => List[DbNutrientEntry] = {
    readWith { cells =>
      Try(
        cells(Locations.NutrientAmount.foodId).toInt,
        cells(Locations.NutrientAmount.nutrientId).toInt,
        cells(Locations.NutrientAmount.nutrientAmount).toDouble,
        cells(Locations.NutrientAmount.nutrientSource),
        (new SimpleDateFormat).parse(cells(Locations.NutrientAmount.nutrientDate))
      ).map {
        case (foodId, nutrientId, nutrientAmount, nutrientSource, date) =>
          DbNutrientEntry(foodId, nutrientAmount, nutrientId, nutrientSource, date)
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

  private def readAndInsert[A <: ToMongoDBObject](parser: String => List[A])(original: String): Unit = {
    val result = parser(original)
    result.foreach { x =>
      MongoFactory.collection.save(x.db)
    }
  }

  def main(args: Array[String]): Unit = {
    readAndInsert(readNutrientData)(Locations.NutrientName.location)
    readAndInsert(readNutrientAmounts)(Locations.NutrientAmount.location)
    readAndInsert(readNutrientSources)(Locations.NutrientSource.location)
    readAndInsert(readFoodNames)(Locations.FoodName.location)
  }

}
