package services.recipe

import db.{ FoodId, IngredientId, RecipeId, UserId }
import services.GenUtils
import slick.dbio.DBIO

import scala.collection.mutable
import scala.concurrent.ExecutionContext

sealed trait MockRecipeService extends RecipeService.Companion {
  protected def fullRecipesByUserId: Seq[(UserId, Seq[FullRecipe])]

  private lazy val recipeMap: mutable.Map[(UserId, RecipeId), Recipe] =
    mutable.Map.from(
      fullRecipesByUserId.flatMap {
        case (userId, fullRecipes) =>
          fullRecipes.map { fullRecipe => (userId, fullRecipe.recipe.id) -> fullRecipe.recipe }
      }
    )

  private lazy val ingredientsMap: mutable.Map[(UserId, RecipeId, IngredientId), Ingredient] =
    mutable.Map.from(
      fullRecipesByUserId.flatMap {
        case (userId, fullRecipes) =>
          fullRecipes.flatMap { fullRecipe =>
            fullRecipe.ingredients.map(ingredient => (userId, fullRecipe.recipe.id, ingredient.id) -> ingredient)
          }
      }
    )

  override def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]] =
    DBIO.successful(recipeMap.collect { case ((uid, _), recipe) if uid == userId => recipe }.toSeq)

  override def getRecipe(userId: UserId, id: RecipeId)(implicit ec: ExecutionContext): DBIO[Option[Recipe]] =
    DBIO.successful(recipeMap.get((userId, id)))

  override def createRecipe(userId: UserId, recipeId: RecipeId, recipeCreation: RecipeCreation)(implicit
      ec: ExecutionContext
  ): DBIO[Recipe] = {
    DBIO.successful {
      val recipe = RecipeCreation.create(recipeId, recipeCreation)
      recipeMap.update((userId, recipeId), recipe)
      recipe
    }
  }

  override def updateRecipe(userId: UserId, recipeUpdate: RecipeUpdate)(implicit ec: ExecutionContext): DBIO[Recipe] =
    recipeMap
      .updateWith(
        (userId, recipeUpdate.id)
      )(
        _.map(RecipeUpdate.update(_, recipeUpdate))
      )
      .fold(DBIO.failed(new Throwable(s"Error updating recipe with recipe id: ${recipeUpdate.id}")): DBIO[Recipe])(
        DBIO.successful
      )

  override def deleteRecipe(userId: UserId, id: RecipeId)(implicit ec: ExecutionContext): DBIO[Boolean] =
    DBIO.successful {
      recipeMap
        .remove((userId, id))
        .isDefined
    }

  override def getIngredients(userId: UserId, recipeId: RecipeId)(implicit
      ec: ExecutionContext
  ): DBIO[List[Ingredient]] =
    DBIO.successful {
      ingredientsMap.collect {
        case ((uid, rId, _), ingredient) if userId == uid && rId == recipeId => ingredient
      }.toList
    }

  override def addIngredient(userId: UserId, ingredientId: IngredientId, ingredientCreation: IngredientCreation)(
      implicit ec: ExecutionContext
  ): DBIO[Ingredient] = {
    DBIO.successful {
      val ingredient = IngredientCreation.create(ingredientId, ingredientCreation)
      ingredientsMap.update((userId, ingredientCreation.recipeId, ingredientId), ingredient)
      ingredient
    }
  }

  override def updateIngredient(userId: UserId, ingredientUpdate: IngredientUpdate)(implicit
      ec: ExecutionContext
  ): DBIO[Ingredient] = {
    val action =
      for {
        recipeId <- ingredientsMap.collectFirst {
          case ((uid, recipeId, ingredientId), _) if uid == userId && ingredientId == ingredientUpdate.id => recipeId
        }
        ingredient <-
          ingredientsMap
            .updateWith(
              (userId, recipeId, ingredientUpdate.id)
            )(
              _.map(IngredientUpdate.update(_, ingredientUpdate))
            )
      } yield ingredient

    action.fold(
      DBIO.failed(new Throwable(s"Error updating recipe entry with id: ${ingredientUpdate.id}")): DBIO[Ingredient]
    )(DBIO.successful)
  }

  override def removeIngredient(userId: UserId, ingredientId: IngredientId)(implicit
      ec: ExecutionContext
  ): DBIO[Boolean] =
    DBIO.successful {
      val deletion = for {
        recipeId <- ingredientsMap.collectFirst {
          case ((uId, recipeId, iId), _) if uId == userId && ingredientId == iId => recipeId
        }
        _ <- ingredientsMap.remove((userId, recipeId, ingredientId))
      } yield ()
      deletion.isDefined
    }

  override def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]] =
    DBIO.successful(GenUtils.allFoods.values.toSeq)

  override def getFoodInfo(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[FoodInfo]] =
    DBIO.successful {
      GenUtils.allFoods
        .get(foodId)
        .map(food => FoodInfo(food.id, food.name))
    }

  override def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]] =
    DBIO.successful(GenUtils.allMeasures)

}

object MockRecipeService {

  def fromCollection(fullRecipes: Seq[(UserId, Seq[FullRecipe])]): RecipeService.Companion =
    new MockRecipeService {
      override protected val fullRecipesByUserId: Seq[(UserId, Seq[FullRecipe])] = fullRecipes
    }

}
