package services.meal

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {
  case object MealNotFound      extends DBError("No meal with the given id for the given user found")
  case object MealEntryNotFound extends DBError("No meal entry with the given id found")
}
