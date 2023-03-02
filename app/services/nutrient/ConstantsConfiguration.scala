package services.nutrient

import pureconfig.{ CamelCase, ConfigFieldMapping, ConfigSource }
import pureconfig.generic.ProductHint
import pureconfig.generic.auto._

case class ConstantsConfiguration(
    timeoutInSeconds: Int
)

object ConstantsConfiguration {
  implicit def hint[A]: ProductHint[A] = ProductHint[A](ConfigFieldMapping(CamelCase, CamelCase))

  val default: ConstantsConfiguration = ConfigSource.default
    .at("constants")
    .loadOrThrow[ConstantsConfiguration]

}
