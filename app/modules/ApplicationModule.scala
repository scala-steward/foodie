package modules

import play.api.{ Configuration, Environment }
import play.api.inject.Binding
import services.meal.MealService
import services.recipe.RecipeService
import services.user.UserService

class ApplicationModule extends play.api.inject.Module {

  override def bindings(environment: Environment, configuration: Configuration): collection.Seq[Binding[_]] = {
    val settings = Seq(
      bind[UserService.Companion].toInstance(UserService.Live),
      bind[UserService].to[UserService.Live],
      bind[RecipeService.Companion].toInstance(RecipeService.Live),
      bind[RecipeService].to[RecipeService.Live],
      bind[MealService.Companion].toInstance(MealService.Live),
      bind[MealService].to[MealService.Live]
    )
    settings
  }

}
