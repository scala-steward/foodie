package db

import java.util.Date

import base.Floating

case class DbNutrientEntry(amount: Floating,
                           data: DbNutrientData,
                           source: String,
                           dateOfEntry: Date) {

}
