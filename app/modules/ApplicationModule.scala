package modules

import play.api.{ Configuration, Environment }
import play.api.inject.Binding
import services.user.UserService

class ApplicationModule extends play.api.inject.Module {

  override def bindings(environment: Environment, configuration: Configuration): collection.Seq[Binding[_]] = {
    val settings = Seq(
      bind[UserService].to[UserService.Live]
    )
    settings
  }

}
