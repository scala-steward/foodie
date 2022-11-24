package services

import play.api.inject.Injector
import play.api.inject.guice.GuiceApplicationBuilder

object TestUtil {

  val injector: Injector = GuiceApplicationBuilder()
    .build()
    .injector

}
