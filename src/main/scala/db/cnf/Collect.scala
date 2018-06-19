package db.cnf

import com.mongodb.casbah.MongoCollection
import db.MongoFactory

object Collect {

  def readFromDb(): MongoCollection = {
    val collection = MongoFactory.collection
    collection
  }
}
