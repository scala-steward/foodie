import org.scalacheck.Properties
import play.api.inject.guice.GuiceApplicationBuilder
import services.user.UserService

import scala.concurrent.Await
import scala.concurrent.duration.Duration

object Initializer extends Properties("Set up database migrations") {

  lazy val userService: UserService = GuiceApplicationBuilder().build().injector.instanceOf[UserService]

  property("populate") = {
    val initializer = Await.result(userService.getByNickname("initializer"), Duration.Inf)
    initializer.isEmpty
  }

}
