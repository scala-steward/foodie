package services.nutrient

sealed abstract class DBError(errorMessage: String) extends Throwable(errorMessage)

object DBError {

  case object ConversionFactorNotFound
      extends DBError("No conversion factor for the given food and chosen measure found")

}
