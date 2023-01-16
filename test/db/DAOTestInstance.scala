package db

import cats.effect.IO
import cats.effect.unsafe.implicits.global
import db.daos.complexIngredient.ComplexIngredientKey
import db.daos.meal.MealKey
import db.daos.recipe.RecipeKey
import db.daos.referenceMap.ReferenceMapKey
import db.daos.referenceMapEntry.ReferenceMapEntryKey
import db.daos.session.SessionKey
import db.generated.Tables
import io.scalaland.chimney.dsl._
import services.common.RequestInterval
import services.complex.food.ComplexFoodIncoming
import services.complex.ingredient.ComplexIngredient
import services.meal.{ Meal, MealEntry }
import services.recipe.{ Ingredient, Recipe }
import slick.jdbc.PostgresProfile.api._
import slickeffect.catsio.implicits._
import util.DateUtil
import utils.TransformerUtils.Implicits._
import utils.date.Date

import scala.collection.mutable
import scala.concurrent.ExecutionContext

abstract class DAOTestInstance[Content, Key](
    contents: Seq[(Key, Content)]
) extends DAOActions[Content, Key] {

  protected val map: mutable.Map[Key, Content] = mutable.Map.from(contents)

  /* Use IO indirection to ensure that a DBIO action may in fact yield different
     values when it is run at different times.
   */
  protected def fromIO[A](a: => A): DBIO[A] = IO(a).to[DBIO]

  override def find(key: Key): DBIO[Option[Content]] =
    fromIO(map.get(key))

  override def delete(key: Key): DBIO[Int] = fromIO(map.remove(key).fold(0)(_ => 1))

  override def insert(content: Content): DBIO[Content] =
    if (map.contains(keyOf(content)))
      DBIO.failed(new Throwable("Duplicate entry"))
    else
      fromIO {
        map.update(keyOf(content), content)
        content
      }

  override def insertAll(contents: Seq[Content]): DBIO[Seq[Content]] =
    fromIO {
      map.addAll(contents.map(content => keyOf(content) -> content))
      contents
    }

  override def update(value: Content)(implicit ec: ExecutionContext): DBIO[Boolean] =
    fromIO {
      map.update(keyOf(value), value)
      true
    }

  override def exists(key: Key): DBIO[Boolean] =
    fromIO(
      map.contains(key)
    )

}

object DAOTestInstance {

  object ComplexFood {

    def instance(contents: Seq[(RecipeId, Tables.ComplexFoodRow)]): db.daos.complexFood.DAO =
      new DAOTestInstance[Tables.ComplexFoodRow, RecipeId](
        contents
      ) with db.daos.complexFood.DAO {

        override def findByKeys(keys: Seq[RecipeId]): DBIO[Seq[Tables.ComplexFoodRow]] =
          fromIO {
            map.collect {
              case (recipeId, complexFood) if keys.contains(recipeId) => complexFood
            }.toList
          }

      }

    def instanceFrom(contents: Seq[(RecipeId, ComplexFoodIncoming)]): db.daos.complexFood.DAO =
      instance(
        contents.map {
          case (recipeId, complexFoodIncoming) =>
            recipeId -> complexFoodIncoming.transformInto[Tables.ComplexFoodRow]
        }
      )

  }

  object ComplexIngredient {

    def instance(contents: Seq[(ComplexIngredientKey, Tables.ComplexIngredientRow)]): db.daos.complexIngredient.DAO =
      new DAOTestInstance[Tables.ComplexIngredientRow, ComplexIngredientKey](
        contents
      ) with db.daos.complexIngredient.DAO {

        override def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.ComplexIngredientRow]] =
          fromIO {
            map.view
              .filterKeys(_.recipeId == recipeId)
              .values
              .toSeq
          }

      }

    def instanceFrom(contents: Seq[(RecipeId, ComplexIngredient)]): db.daos.complexIngredient.DAO =
      instance(
        contents.map {
          case (recipeId, complexIngredient) =>
            ComplexIngredientKey(recipeId, complexIngredient.complexFoodId) ->
              complexIngredient.transformInto[Tables.ComplexIngredientRow]
        }
      )

  }

  object Ingredient {

    def instance(contents: Seq[(IngredientId, Tables.RecipeIngredientRow)]): db.daos.ingredient.DAO =
      new DAOTestInstance[Tables.RecipeIngredientRow, IngredientId](
        contents
      ) with db.daos.ingredient.DAO {

        override def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.RecipeIngredientRow]] =
          fromIO {
            map.values.collect {
              case ingredient if ingredient.recipeId.transformInto[RecipeId] == recipeId => ingredient
            }.toList
          }

      }

    def instanceFrom(contents: Seq[(RecipeId, Ingredient)]): db.daos.ingredient.DAO =
      instance(
        contents.map {
          case (recipeId, ingredient) =>
            ingredient.id -> (ingredient, recipeId).transformInto[Tables.RecipeIngredientRow]
        }
      )

  }

  object Meal {

    def instance(contents: Seq[(MealKey, Tables.MealRow)]): db.daos.meal.DAO =
      new DAOTestInstance[Tables.MealRow, MealKey](
        contents
      ) with db.daos.meal.DAO {

        override def allInInterval(userId: UserId, requestInterval: RequestInterval): DBIO[Seq[Tables.MealRow]] =
          fromIO {
            map
              .filter {
                case (key, meal) =>
                  val interval = DateUtil.toInterval(
                    requestInterval.from.map(_.transformInto[Date]),
                    requestInterval.to.map(_.transformInto[Date])
                  )

                  key.userId == userId &&
                  interval.contains(meal.consumedOnDate.toLocalDate.transformInto[Date])
              }
              .values
              .toList
          }

      }

    def instanceFrom(contents: Seq[(UserId, Meal)]): db.daos.meal.DAO =
      instance(
        contents.map { case (userId, meal) => MealKey(userId, meal.id) -> (meal, userId).transformInto[Tables.MealRow] }
      )

  }

  object MealEntry {

    def instance(contents: Seq[(MealEntryId, Tables.MealEntryRow)]): db.daos.mealEntry.DAO =
      new DAOTestInstance[Tables.MealEntryRow, MealEntryId](
        contents
      ) with db.daos.mealEntry.DAO {

        override def findAllFor(mealId: MealId): DBIO[Seq[Tables.MealEntryRow]] =
          fromIO {
            map.values
              .filter(_.mealId.transformInto[MealId] == mealId)
              .toList
          }

      }

    def instanceFrom(contents: Seq[(MealId, MealEntry)]): db.daos.mealEntry.DAO =
      instance(
        contents.map {
          case (mealId, mealEntry) => mealEntry.id -> (mealEntry, mealId).transformInto[Tables.MealEntryRow]
        }
      )

  }

  object Recipe {

    def instance(contents: Seq[(RecipeKey, Tables.RecipeRow)]): db.daos.recipe.DAO =
      new DAOTestInstance[Tables.RecipeRow, RecipeKey](
        contents
      ) with db.daos.recipe.DAO {

        override def findAllFor(userId: UserId): DBIO[Seq[Tables.RecipeRow]] =
          fromIO {
            map.values
              .filter(_.userId.transformInto[UserId] == userId)
              .toList
          }

      }

    def instanceFrom(contents: Seq[(UserId, Recipe)]): db.daos.recipe.DAO =
      instance(
        contents.map {
          case (userId, recipe) => RecipeKey(userId, recipe.id) -> (recipe, userId).transformInto[Tables.RecipeRow]
        }
      )

  }

  object ReferenceMap {

    def instance(contents: Seq[(ReferenceMapKey, Tables.ReferenceMapRow)]): db.daos.referenceMap.DAO =
      new DAOTestInstance[Tables.ReferenceMapRow, ReferenceMapKey](
        contents
      ) with db.daos.referenceMap.DAO {

        override def findAllFor(userId: UserId): DBIO[Seq[Tables.ReferenceMapRow]] =
          fromIO {
            map.view
              .filterKeys(_.userId == userId)
              .values
              .toList
          }

      }

  }

  object ReferenceMapEntry {

    def instance(contents: Seq[(ReferenceMapEntryKey, Tables.ReferenceEntryRow)]): db.daos.referenceMapEntry.DAO =
      new DAOTestInstance[Tables.ReferenceEntryRow, ReferenceMapEntryKey](
        contents
      ) with db.daos.referenceMapEntry.DAO {

        override def findAllFor(referenceMapId: ReferenceMapId): DBIO[Seq[Tables.ReferenceEntryRow]] =
          fromIO {
            map.view
              .filterKeys(_.referenceMapId == referenceMapId)
              .values
              .toList
          }

      }

  }

  object Session {

    def instance(contents: Seq[(SessionKey, Tables.SessionRow)]): db.daos.session.DAO =
      new DAOTestInstance[Tables.SessionRow, SessionKey](
        contents
      ) with db.daos.session.DAO {

        override def deleteAllFor(userId: UserId): DBIO[Int] =
          fromIO {
            map.keys
              .filter(_.userId == userId)
              .flatMap(map.remove)
              .size
          }

      }

  }

  object User {

    def instance(contents: Seq[(UserId, Tables.UserRow)]): db.daos.user.DAO =
      new DAOTestInstance[Tables.UserRow, UserId](
        contents
      ) with db.daos.user.DAO {

        override def findByNickname(nickname: String): DBIO[Seq[Tables.UserRow]] =
          fromIO {
            map.values
              .filter(_.nickname == nickname)
              .toList
          }

        override def findByIdentifier(identifier: String): DBIO[Seq[Tables.UserRow]] =
          fromIO {
            map.values
              .filter(user => user.email == identifier || user.nickname == identifier)
              .toList
          }

      }

  }

}
