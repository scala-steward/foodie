package action

import db.SessionId
import play.api.mvc.{ Request, WrappedRequest }
import services.user.User

case class UserRequest[A](
    request: Request[A],
    user: User,
    sessionId: SessionId
) extends WrappedRequest[A](request)
