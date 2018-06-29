package db.cnf

import java.io.File

object Locations {
  
  object NutrientName {
    val location: String = s"db${File.separator}NUTRIENT NAME.csv"
    val id: Int = 0
    val name: Int = 4
    val prefixedUnit: Int = 3
  }

  object NutrientAmount {
    val location: String = s"db${File.separator}NUTRIENT AMOUNT.csv"

    val foodId: Int = 0
    val nutrientId: Int = 1
    val nutrientAmount: Int = 2
    val nutrientSource: Int = 5
    val nutrientDate: Int = 6
  }

  object NutrientSource {
    val location: String = s"db${File.separator}NUTRIENT SOURCE.csv"

    val nutrientId: Int = 0
    val nutrientSource: Int = 2
  }

  object FoodName {
    val location: String = s"db${File.separator}FOOD NAME.csv"

    val foodId: Int = 0
    val foodName: Int = 4
  }

  object ConversionFactor {
    val location: String = s"db${File.separator}CONVERSION FACTOR.csv"

    val foodId: Int = 0
    val measureId: Int = 1
    val factor: Int = 2
  }

  object MeasureName {
    val location: String = s"db${File.separator}MEASURE NAME.csv"

    val measureId: Int = 0
    val name: Int = 1
  }

}
