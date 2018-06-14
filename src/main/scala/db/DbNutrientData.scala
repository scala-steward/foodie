package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject
import physical.{PUnit, Prefix}
import scalaz.Scalaz._

/**
  * The data base representation of nutrient related data.
  *
  * @param nutrientId The id of the nutrient.
  * @param name       The name of the nutrient.
  * @param unit       The type of unit associated with this nutrient.
  * @param prefix     The type of prefix associated with the nutrient and its unit.
  */
case class DbNutrientData(nutrientId: Id,
                          name: String,
                          unit: PUnit[_],
                          prefix: Prefix[_]) extends ToMongoDBObject {

  override def db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbNutrientData.nutrientId -> nutrientId,
      DbNutrientData.name -> name,
      DbNutrientData.unit -> unit.name,
      DbNutrientData.prefix -> prefix.name
    )
    builder.result()
  }

}

object DbNutrientData {
  val nutrientId: String = "nutrientId"
  val name: String = "name"
  val unit: String = "unit"
  val prefix: String = "prefix"

  object Implicits {
    implicit val nutrientDataFromDB: FromMongoDBObject[DbNutrientData] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](nutrientId) |@|
        mongoDBObject.getAs[String](name) |@|
        mongoDBObject.getAs[PUnit[_]](unit) |@|
        mongoDBObject.getAs[Prefix[_]](prefix)) (DbNutrientData.apply)
    }
  }
}
