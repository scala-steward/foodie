package db

import java.util.Date

import base.Floating
import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

import scalaz.Scalaz._

/**
  * A database representation of a nutrient entry.
  *
  * @param foodId      The food id of the entry.
  * @param amount      The amount of the nutrient in the food.
  * @param nutrientId  The id of the nutrient in the entry.
  * @param source      The source, where this information originates from.
  */
case class DbNutrientEntry(foodId: Id,
                           amount: Floating,
                           nutrientId: Id,
                           source: String) extends ToMongoDBObject {
  override def db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbNutrientEntry.foodId -> foodId,
      DbNutrientEntry.amount -> amount.doubleValue(),
      DbNutrientEntry.nutrientId -> nutrientId,
      DbNutrientEntry.source -> source
    )
    builder.result()
  }
}

object DbNutrientEntry {

  def apply(foodId: Id,
            amount: Double,
            nutrientId: Id,
            source: String): DbNutrientEntry =
    DbNutrientEntry(foodId, amount: BigDecimal, nutrientId, source)

  val foodId: String = "foodId"
  val amount: String = "amount"
  val nutrientId: String = "nutrientId"
  val source: String = "source"
  val dateOfEntry: String = "dateOfEntry"

  object Implicits {
    implicit val nutrientEntryFromDB: FromMongoDBObject[DbNutrientEntry] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](foodId) |@|
        mongoDBObject.getAs[Double](amount) |@|
        mongoDBObject.getAs[Id](nutrientId) |@|
        mongoDBObject.getAs[String](source)) (DbNutrientEntry.apply)
    }
  }

}
