package services.stats

import javax.inject.Inject
import scala.concurrent.Future

trait StatsService {

  def nutrientsOverTime(requestInterval: RequestInterval)

}

object StatsService {

  class Live @Inject() (companion: Companion) extends StatsService {
    override def nutrientsOverTime(requestInterval: RequestInterval) = ???
  }

  trait Companion

  object Live extends Companion
}
