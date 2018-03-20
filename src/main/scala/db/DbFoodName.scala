package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject
import db.cnf.FromDB.Id

import scalaz.Scalaz.{Id => _, _}

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

  protected val foodIdLabel: String = "foodId"
  protected val nameLabel: String = "name"

  object Implicits {
    implicit val fromDB: FromMongoDBObject[DbFoodName] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](foodIdLabel) |@| mongoDBObject.getAs[String](nameLabel))(DbFoodName.apply)
    }

  }

}
