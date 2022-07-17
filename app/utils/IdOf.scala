package utils

import io.scalaland.chimney.Transformer
import shapeless.tag
import shapeless.tag.@@

import java.util.UUID

trait IdOf[A] {

  implicit val fromUUID: Transformer[UUID, UUID @@ A] = tag[A](_)
  implicit val toUUID: Transformer[UUID @@ A, UUID]   = _: UUID

}
