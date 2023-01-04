package db

import db.DAOActions.FindPredicate
import slick.jdbc.PostgresProfile.api._
import slick.lifted.{ Rep, TableQuery }
import slick.relational.RelationalProfile

import scala.concurrent.ExecutionContext

trait DAOActions[Content, Table <: RelationalProfile#Table[Content], Key] {

  protected def dbTable: TableQuery[Table]

  protected def compareByKey: FindPredicate[Table, Key]

  def find(key: Key): DBIO[Option[Content]] =
    findQuery(key).result.headOption

  def findPartial(
      predicate: Table => Rep[Boolean]
  ): DBIO[Seq[Content]] =
    findPartialQuery(predicate).result

  private def findPartialQuery(
      predicate: Table => Rep[Boolean]
  ): Query[Table, Content, Seq] =
    dbTable.filter(predicate)

  def delete(key: Key): DBIO[Int] =
    findQuery(key).delete

  def insert(
      content: Content
  ): DBIO[Content] =
    dbTable.returning(dbTable) += content

  def insertAll(
      contents: Seq[Content]
  ): DBIO[Seq[Content]] =
    dbTable.returning(dbTable) ++= contents

  def update(value: Content)(keyOf: Content => Key)(implicit ec: ExecutionContext): DBIO[Boolean] =
    findQuery(keyOf(value))
      .update(value)
      .map(_ == 1)

  def exists(key: Key): DBIO[Boolean] =
    findQuery(key).exists.result

  private def findQuery(key: Key): Query[Table, Content, Seq] =
    findPartialQuery(compareByKey(_, key))

}

object DAOActions {
  type FindPredicate[T, Part] = (T, Part) => Rep[Boolean]

  abstract class Instance[Content, Table <: RelationalProfile#Table[Content], Key](
      table: TableQuery[Table],
      compare: (Table, Key) => Rep[Boolean]
  ) extends DAOActions[Content, Table, Key] {
    override val dbTable: TableQuery[Table]              = table
    override val compareByKey: FindPredicate[Table, Key] = (table, key) => compare(table, key)
  }

}
