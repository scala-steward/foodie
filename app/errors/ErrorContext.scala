package errors

sealed trait ErrorContext {
  def message: String
}

object ErrorContext {

  sealed abstract class ServerErrorInstance(override val message: String) extends ErrorContext

  implicit class ErrorContextToServerError(val errorContext: ErrorContext) extends AnyVal {
    def asServerError: ServerError = ServerError.fromContext(errorContext)
  }

  object Login {
    case object Failure extends ServerErrorInstance("Invalid combination of user name and password.")
  }

  object Authentication {

    object Token {
      case object Decoding extends ServerErrorInstance("Error decoding JWT: Format or signature is wrong")
      case object Content  extends ServerErrorInstance("Error parsing JWT content: Unexpected format")
      case object Missing  extends ServerErrorInstance("Missing JWT")
    }

  }

  object User {
    case object NotFound extends ServerErrorInstance("No user with the given id found")
  }

}
