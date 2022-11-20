package services.nutrient

import org.scalacheck.Properties
import play.api.inject.guice.GuiceApplicationBuilder

import scala.concurrent.Await
import scala.concurrent.duration.Duration

object TestDB extends Properties("DbTest") {
  lazy val nutrientService: NutrientService = GuiceApplicationBuilder().build().injector.instanceOf[NutrientService]

  property("foo") = {
    val all = Await.result(nutrientService.all, Duration.Inf)
    all.nonEmpty
  }
}
