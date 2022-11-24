package services

import db.generated.Tables
import play.api.db.slick.DatabaseConfigProvider
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._

import scala.concurrent.Await
import scala.concurrent.duration.{ Duration, _ }

object DBTestUtil {

  val defaultAwaitTimeout: Duration  = 2.minutes
  private val databaseConfigProvider = TestUtil.injector.instanceOf[DatabaseConfigProvider]

  def clearDb(): Unit =
    Await.result(
      databaseConfigProvider
        .get[PostgresProfile]
        .db
        .run(
          /* The current structure links everything to users at the
             root level, which is why it is sufficient to delete all
             users to also clear all non-CNF tables.
           */
          Tables.User.delete
        ),
      defaultAwaitTimeout
    )

}
