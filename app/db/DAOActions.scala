package db

import slick.jdbc.PostgresProfile.api._
import slick.lifted.{ Rep, TableQuery }
import slick.relational.RelationalProfile

import scala.concurrent.ExecutionContext

trait DAOActions[Content, Table, Key] {

  def find(key: Key): DBIO[Option[Content]]

  def findBy(
      predicate: Table => Rep[Boolean]
  ): DBIO[Seq[Content]]

  def delete(key: Key): DBIO[Int]

  def deleteBy(predicate: Table => Rep[Boolean]): DBIO[Int]

  def insert(content: Content): DBIO[Content]

  def insertAll(contents: Seq[Content]): DBIO[Seq[Content]]
  def update(value: Content)(keyOf: Content => Key)(implicit ec: ExecutionContext): DBIO[Boolean]

  def exists(key: Key): DBIO[Boolean]

}

object DAOActions {

  abstract class Instance[Content, Table <: RelationalProfile#Table[Content], Key](
      table: TableQuery[Table],
      compare: (Table, Key) => Rep[Boolean]
  ) extends DAOActions[Content, Table, Key] {

    override def find(key: Key): DBIO[Option[Content]] =
      findQuery(key).result.headOption

    override def findBy(
        predicate: Table => Rep[Boolean]
    ): DBIO[Seq[Content]] =
      findPartialQuery(predicate).result

    override def delete(key: Key): DBIO[Int] =
      findQuery(key).delete

    override def deleteBy(predicate: Table => Rep[Boolean]): DBIO[Int] =
      findPartialQuery(predicate).delete

    override def insert(
        content: Content
    ): DBIO[Content] =
      table.returning(table) += content

    override def insertAll(
        contents: Seq[Content]
    ): DBIO[Seq[Content]] =
      table.returning(table) ++= contents

    override def update(value: Content)(keyOf: Content => Key)(implicit ec: ExecutionContext): DBIO[Boolean] =
      findQuery(keyOf(value))
        .update(value)
        .map(_ == 1)

    override def exists(key: Key): DBIO[Boolean] =
      findQuery(key).exists.result

    private def findQuery(key: Key): Query[Table, Content, Seq] =
      findPartialQuery(compare(_, key))

    private def findPartialQuery(
        predicate: Table => Rep[Boolean]
    ): Query[Table, Content, Seq] =
      table.filter(predicate)

  }

}
