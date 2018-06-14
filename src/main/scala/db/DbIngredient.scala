package db

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObject

/**
  * A database representation of an ingredient.
  *
  * @param ingredientId The id of the ingredient.
  * @param name         The name of the ingredient.
  * @param nutrients    The list of nutrients in the ingredient.
  */
case class DbIngredient(ingredientId: Id,
                        name: String,
                        nutrients: Iterable[DbNutrientEntry]) extends ToMongoDBObject {
  override def db: MongoDBObject = {
    val builder = MongoDBObject.newBuilder
    builder ++= Seq(
      "ingredientId" -> ingredientId,
      "name" -> name,
      "nutrients" -> nutrients.map(_.db.toMap)
    )
    builder.result()
  }
}
