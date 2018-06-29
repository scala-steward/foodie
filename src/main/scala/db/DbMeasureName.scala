package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

import scalaz.Scalaz._

case class DbMeasureName(measureId: Id,
                         name: String) extends ToMongoDBObject {
  override val db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbFoodName.foodIdLabel -> measureId,
      DbFoodName.nameLabel -> name
    )
    builder.result()
  }

}

object DbMeasureName {

  val foodIdLabel: String = "foodId"
  val nameLabel: String = "name"

  object Implicits {
    implicit val foodNameFromDB: FromMongoDBObject[DbMeasureName] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](foodIdLabel) |@| mongoDBObject.getAs[String](nameLabel))(DbMeasureName.apply)
    }

  }

}
