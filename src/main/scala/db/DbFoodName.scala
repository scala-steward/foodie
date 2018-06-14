package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

import scalaz.Scalaz._

/**
  * The database representation of the food name associations.
  * @param foodId The id of the food.
  * @param name The name of the food.
  */
case class DbFoodName(foodId: Id, name: String) extends ToMongoDBObject {
  override def db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbFoodName.foodIdLabel -> foodId,
      DbFoodName.nameLabel -> name
    )
    builder.result()
  }
}

object DbFoodName {

  val foodIdLabel: String = "foodId"
  val nameLabel: String = "name"

  object Implicits {
    implicit val foodNameFromDB: FromMongoDBObject[DbFoodName] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](foodIdLabel) |@| mongoDBObject.getAs[String](nameLabel))(DbFoodName.apply)
    }

  }

}
