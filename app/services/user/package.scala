package services

import shapeless.tag.@@

import java.util.UUID

package object user {

  sealed trait UserTag

  type UserId = UUID @@ UserTag

}
