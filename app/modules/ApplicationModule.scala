package modules

import play.api.inject.Binding
import play.api.{ Configuration, Environment }
import services.complex.food.ComplexFoodService
import services.complex.ingredient.ComplexIngredientService
import services.meal.MealService
import services.nutrient.NutrientService
import services.recipe.RecipeService
import services.reference.ReferenceService
import services.stats.StatsService
import services.user.UserService

class ApplicationModule extends play.api.inject.Module {

  override def bindings(environment: Environment, configuration: Configuration): collection.Seq[Binding[_]] = {
    val settings = Seq(
      bind[db.daos.recipe.DAO].toInstance(db.daos.recipe.DAO.instance),
      bind[UserService.Companion].toInstance(services.user.Live.Companion),
      bind[UserService].to[services.user.Live],
      bind[RecipeService.Companion].to[services.recipe.Live.Companion],
      bind[RecipeService].to[services.recipe.Live],
      bind[ComplexIngredientService.Companion].to[services.complex.ingredient.Live.Companion],
      bind[ComplexIngredientService].to[services.complex.ingredient.Live],
      bind[ComplexFoodService.Companion].to[services.complex.food.Live.Companion],
      bind[ComplexFoodService].to[services.complex.food.Live],
      bind[MealService.Companion].toInstance(services.meal.Live.Companion),
      bind[MealService].to[services.meal.Live],
      bind[NutrientService.Companion].toInstance(services.nutrient.Live.Companion),
      bind[NutrientService].to[services.nutrient.Live],
      bind[StatsService.Companion].to[services.stats.Live.Companion],
      bind[StatsService].to[services.stats.Live],
      bind[ReferenceService.Companion].toInstance(services.reference.Live.Companion),
      bind[ReferenceService].to[services.reference.Live]
    )
    settings
  }

}
