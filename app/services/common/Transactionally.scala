package services.common

import slick.dbio.{ DBIOAction, NoStream }
import slick.jdbc.PostgresProfile
import slick.jdbc.PostgresProfile.api._

import scala.concurrent.Future

object Transactionally {

  object syntax {

    implicit class WithRunTransactionally(private val databaseDef: PostgresProfile#Backend#Database) extends AnyVal {

      def runTransactionally[A](dbio: DBIOAction[A, NoStream, Nothing]): Future[A] =
        databaseDef.run(dbio.transactionally)

    }

  }

}
