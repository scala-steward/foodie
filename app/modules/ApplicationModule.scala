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
      bind[db.daos.complexFood.DAO].toInstance(db.daos.complexFood.DAO.instance),
      bind[db.daos.complexIngredient.DAO].toInstance(db.daos.complexIngredient.DAO.instance),
      bind[db.daos.ingredient.DAO].toInstance(db.daos.ingredient.DAO.instance),
      bind[db.daos.meal.DAO].toInstance(db.daos.meal.DAO.instance),
      bind[db.daos.mealEntry.DAO].toInstance(db.daos.mealEntry.DAO.instance),
      bind[db.daos.recipe.DAO].toInstance(db.daos.recipe.DAO.instance),
      bind[db.daos.referenceMap.DAO].toInstance(db.daos.referenceMap.DAO.instance),
      bind[db.daos.referenceMapEntry.DAO].toInstance(db.daos.referenceMapEntry.DAO.instance),
      bind[db.daos.session.DAO].toInstance(db.daos.session.DAO.instance),
      bind[db.daos.user.DAO].toInstance(db.daos.user.DAO.instance),
      bind[UserService.Companion].to[services.user.Live.Companion],
      bind[UserService].to[services.user.Live],
      bind[RecipeService.Companion].to[services.recipe.Live.Companion],
      bind[RecipeService].to[services.recipe.Live],
      bind[ComplexIngredientService.Companion].to[services.complex.ingredient.Live.Companion],
      bind[ComplexIngredientService].to[services.complex.ingredient.Live],
      bind[ComplexFoodService.Companion].to[services.complex.food.Live.Companion],
      bind[ComplexFoodService].to[services.complex.food.Live],
      bind[MealService.Companion].to[services.meal.Live.Companion],
      bind[MealService].to[services.meal.Live],
      bind[NutrientService.Companion].to[services.nutrient.Live.Companion],
      bind[NutrientService].to[services.nutrient.Live],
      bind[StatsService.Companion].to[services.stats.Live.Companion],
      bind[StatsService].to[services.stats.Live],
      bind[ReferenceService.Companion].to[services.reference.Live.Companion],
      bind[ReferenceService].to[services.reference.Live],
      bind[services.duplication.recipe.Duplication.Companion].to[services.duplication.recipe.Live.Companion],
      bind[services.duplication.recipe.Duplication].to[services.duplication.recipe.Live]
    )
    settings
  }

}
