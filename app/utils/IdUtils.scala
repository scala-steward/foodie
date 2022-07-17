package utils

import io.scalaland.chimney.Transformer
import shapeless.tag
import shapeless.tag.@@

object IdUtils {

  object Implicits {
    implicit def fromUntagged[A, Tag]: Transformer[A, A @@ Tag] = tag[Tag](_)
    implicit def toUntagged[A, Tag]: Transformer[A @@ Tag, A]   = id => id: A
  }

}
