package db.cnf

import db.MongoFactory

object Collect {

  def readFromDb() = {
    val collection = MongoFactory.collection
    collection
  }
}
