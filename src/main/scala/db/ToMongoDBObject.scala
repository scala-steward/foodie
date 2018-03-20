package db

import com.mongodb.casbah.commons.MongoDBObject

trait ToMongoDBObject {

  def db: MongoDBObject
}
