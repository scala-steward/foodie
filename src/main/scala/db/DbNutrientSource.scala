package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

import scalaz.Scalaz._

/**
  * A database representation of a nutrient source.
  * @param nutrientId The id of the nutrient.
  * @param source The source where the information about this content originates from.
  */
case class DbNutrientSource(nutrientId: Id, source: String) extends ToMongoDBObject {
  override def db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbNutrientSource.nutrientIdLabel -> nutrientId,
      DbNutrientSource.sourceLabel -> source
    )
    builder.result()
  }
}

object DbNutrientSource {

  val nutrientIdLabel: String = "foodId"
  val sourceLabel: String = "name"

  object Implicits {
    implicit val fromDB: FromMongoDBObject[DbNutrientSource] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](nutrientIdLabel) |@| mongoDBObject.getAs[String](sourceLabel))(DbNutrientSource.apply)
    }

  }

}