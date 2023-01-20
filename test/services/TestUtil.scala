package services

import play.api.db.slick.DatabaseConfigProvider
import play.api.inject.Injector
import play.api.inject.guice.GuiceApplicationBuilder

object TestUtil {

  val injector: Injector = GuiceApplicationBuilder()
    .build()
    .injector

  val databaseConfigProvider: DatabaseConfigProvider = injector.instanceOf[DatabaseConfigProvider]

  def measure[A](label: String)(a: => A): A = {
    val start  = System.currentTimeMillis()
    val result = a
    val end    = System.currentTimeMillis()
    pprint.log(s"$label: ${end - start}ms")
    result
  }

}
