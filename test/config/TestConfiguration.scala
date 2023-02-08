package config

import pureconfig.generic.ProductHint
import pureconfig.generic.auto._
import pureconfig.{ CamelCase, ConfigFieldMapping, ConfigSource }

case class TestConfiguration(
    property: PropertyTestConfiguration
)

object TestConfiguration {
  implicit def hint[A]: ProductHint[A] = ProductHint[A](ConfigFieldMapping(CamelCase, CamelCase))

  val default: TestConfiguration = ConfigSource.default
    .at("test")
    .loadOrThrow[TestConfiguration]

}
