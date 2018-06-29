package db

import base.Floating
import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

import scalaz.Scalaz._

case class DbConversionFactor(foodId: Id,
                              measureId: Id,
                              factor: Floating) extends ToMongoDBObject {
  override val db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      DbConversionFactor.foodIdLabel -> foodId,
      DbConversionFactor.measureIdLabel -> measureId,
      DbConversionFactor.factorLabel -> factor.doubleValue()
    )
    builder.result()
  }
}

object DbConversionFactor {

  def apply(foodId: Id, measureId: Id,factor: Double): DbConversionFactor =
    DbConversionFactor(foodId, measureId, factor: BigDecimal)

  val foodIdLabel: String = "foodId"
  val measureIdLabel: String = "measureId"
  val factorLabel: String = "factor"

  object Implicits {
    implicit val conversionFromDB: FromMongoDBObject[DbConversionFactor] = (mongoDBObject: MongoDBObject) => {
      (mongoDBObject.getAs[Id](foodIdLabel) |@|
        mongoDBObject.getAs[Id](measureIdLabel) |@|
        mongoDBObject.getAs[Double](factorLabel) ) (DbConversionFactor.apply)
    }
  }
}
