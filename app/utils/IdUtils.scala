package utils

import io.scalaland.chimney.Transformer
import shapeless.tag
import shapeless.tag.@@

import java.util.UUID

object IdUtils {

  object Implicits {
    implicit def fromUUID[A]: Transformer[UUID, UUID @@ A] = tag[A](_)
    implicit def toUUID[A]: Transformer[UUID @@ A, UUID]   = id => id: UUID
  }

}
