package services.user

import io.scalaland.chimney.Transformer
import shapeless.tag
import shapeless.tag.@@

import java.util.UUID

sealed trait UserId

object UserId {

  implicit val fromUUID: Transformer[UUID, UUID @@ UserId] = tag[UserId](_)
  implicit val toUUID: Transformer[UUID @@ UserId, UUID]   = userId => userId: UUID

}
