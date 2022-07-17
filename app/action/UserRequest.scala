package action

import play.api.mvc.{ Request, WrappedRequest }
import services.user.User

case class UserRequest[A](
    request: Request[A],
    user: User
) extends WrappedRequest[A](request)
