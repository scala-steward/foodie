package services.recipe

import db.{ FoodId, IngredientId, RecipeId, UserId }
import errors.ServerError
import slick.dbio.DBIO

import scala.concurrent.{ ExecutionContext, Future }

trait RecipeService {
  def allFoods: Future[Seq[Food]]

  def getFoodInfo(foodId: FoodId): Future[Option[FoodInfo]]
  def allMeasures: Future[Seq[Measure]]

  def allRecipes(userId: UserId): Future[Seq[Recipe]]
  def getRecipe(userId: UserId, id: RecipeId): Future[Option[Recipe]]
  def createRecipe(userId: UserId, recipeCreation: RecipeCreation): Future[ServerError.Or[Recipe]]
  def updateRecipe(userId: UserId, recipeUpdate: RecipeUpdate): Future[ServerError.Or[Recipe]]
  def deleteRecipe(userId: UserId, id: RecipeId): Future[Boolean]

  def getIngredients(userId: UserId, recipeId: RecipeId): Future[List[Ingredient]]
  def addIngredient(userId: UserId, ingredientCreation: IngredientCreation): Future[ServerError.Or[Ingredient]]
  def updateIngredient(userId: UserId, ingredientUpdate: IngredientUpdate): Future[ServerError.Or[Ingredient]]
  def removeIngredient(userId: UserId, ingredientId: IngredientId): Future[Boolean]
}

object RecipeService {

  trait Companion {
    def allFoods(implicit ec: ExecutionContext): DBIO[Seq[Food]]

    def getFoodInfo(foodId: FoodId)(implicit ec: ExecutionContext): DBIO[Option[FoodInfo]]
    def allMeasures(implicit ec: ExecutionContext): DBIO[Seq[Measure]]

    def allRecipes(userId: UserId)(implicit ec: ExecutionContext): DBIO[Seq[Recipe]]

    def getRecipe(
        userId: UserId,
        id: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Option[Recipe]]

    def getRecipes(
        userId: UserId,
        ids: Seq[RecipeId]
    )(implicit ec: ExecutionContext): DBIO[Seq[Recipe]]

    def createRecipe(
        userId: UserId,
        id: RecipeId,
        recipeCreation: RecipeCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def updateRecipe(
        userId: UserId,
        recipeUpdate: RecipeUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Recipe]

    def deleteRecipe(
        userId: UserId,
        id: RecipeId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

    def getIngredients(
        userId: UserId,
        recipeId: RecipeId
    )(implicit ec: ExecutionContext): DBIO[List[Ingredient]]

    def getAllIngredients(
        userId: UserId,
        recipeIds: Seq[RecipeId]
    )(implicit ec: ExecutionContext): DBIO[Map[RecipeId, List[Ingredient]]]

    def addIngredient(
        userId: UserId,
        id: IngredientId,
        ingredientCreation: IngredientCreation
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def updateIngredient(
        userId: UserId,
        ingredientUpdate: IngredientUpdate
    )(implicit
        ec: ExecutionContext
    ): DBIO[Ingredient]

    def removeIngredient(
        userId: UserId,
        id: IngredientId
    )(implicit ec: ExecutionContext): DBIO[Boolean]

  }

}
