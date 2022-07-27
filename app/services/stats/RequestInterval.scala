package services.stats

import java.time.LocalDate

case class RequestInterval(
    from: Option[LocalDate],
    to: Option[LocalDate]
)
