package db

import com.mongodb.casbah.commons.MongoDBObject

/**
  * Denotes readability from a mongoDB object to some type.
  *
  * @tparam A The possible result type.
  */
trait FromMongoDBObject[A] {
  /**
    * Attempt to translate the given object into a desired type.
    *
    * @param mongoDBObject The object that will be parsed.
    * @return Possibly a concrete representation of the JSON denoted object.
    */
  def fromDB(mongoDBObject: MongoDBObject): Option[A]
}
