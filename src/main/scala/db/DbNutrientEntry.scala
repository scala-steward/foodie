package db

import java.util.Date

import base.Floating
import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject
import db.cnf.FromDB.Id

import scalaz.Scalaz._

/**
  * A database representation of a nutrient entry.
  *
  * @param foodId      The food id of the entry.
  * @param amount      The amount of the nutrient in the food.
  * @param nutrientId  The id of the nutrient in the entry.
  * @param source      The source, where this information originates from.
  * @param dateOfEntry The date when this information has been obtained.
  */
case class DbNutrientEntry(foodId: Id,
                           amount: Floating,
                           nutrientId: Id,
                           source: String,
                           dateOfEntry: Date) extends ToMongoDBObject {
  override def db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbNutrientEntry.foodId -> foodId,
      DbNutrientEntry.amount -> amount.toString(),
      DbNutrientEntry.nutrientId -> nutrientId,
      DbNutrientEntry.source -> source,
      DbNutrientEntry.dateOfEntry -> dateOfEntry.toString
    )
    builder.result()
  }
}

object DbNutrientEntry {

  protected val foodId: String = "foodId"
  protected val amount: String = "amount"
  protected val nutrientId: String = "nutrientId"
  protected val source: String = "source"
  protected val dateOfEntry: String = "dateOfEntry"

  object Implicits {
    implicit val nutrientEntryFromDB: FromMongoDBObject[DbNutrientEntry] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](foodId) |@|
        mongoDBObject.getAs[Floating](amount) |@|
        mongoDBObject.getAs[Id](nutrientId) |@|
        mongoDBObject.getAs[String](source) |@|
        mongoDBObject.getAs[Date](dateOfEntry)) (DbNutrientEntry.apply)
    }
  }

}
