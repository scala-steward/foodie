package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

import scalaz.Scalaz._

case class DbMeasureName(measureId: Id,
                         name: String) extends ToMongoDBObject {
  override val db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbMeasureName.measureId -> measureId,
      DbMeasureName.nameLabel -> name
    )
    builder.result()
  }

}

object DbMeasureName {

  val measureId: String = "measureId"
  val nameLabel: String = "name"

  object Implicits {
    implicit val measureNameFromDB: FromMongoDBObject[DbMeasureName] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](measureId) |@| mongoDBObject.getAs[String](nameLabel))(DbMeasureName.apply)
    }

  }

}
