package db

import com.mongodb.casbah.{MongoClient, MongoCollection}

object MongoFactory {
  private val server = "localhost"
  private val databaseName = "foodie"
  private val collectionName = "ingredients"
  val client = MongoClient(server)
  val collection: MongoCollection = client(databaseName)(collectionName)
}
