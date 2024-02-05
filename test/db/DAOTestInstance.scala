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
import services.reference.{ ReferenceEntry, ReferenceMap }
import slick.jdbc.PostgresProfile.api._
import slickeffect.catsio.implicits._
import util.DateUtil
import utils.TransformerUtils.Implicits._
import utils.date.Date

import java.sql
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

    def instanceFrom(contents: Seq[(UserId, RecipeId, ComplexFoodIncoming)]): db.daos.complexFood.DAO =
      instance(
        contents.map { case (userId, recipeId, complexFoodIncoming) =>
          recipeId -> ComplexFoodIncoming
            .TransformableToDB(userId, complexFoodIncoming)
            .transformInto[Tables.ComplexFoodRow]
        }
      )

  }

  object ComplexIngredient {

    def instance(contents: Seq[(ComplexIngredientKey, Tables.ComplexIngredientRow)]): db.daos.complexIngredient.DAO =
      new DAOTestInstance[Tables.ComplexIngredientRow, ComplexIngredientKey](
        contents
      ) with db.daos.complexIngredient.DAO {

        override def findAllFor(recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.ComplexIngredientRow]] =
          fromIO {
            map.view
              .filterKeys(recipe => recipeIds.contains(recipe.recipeId))
              .values
              .toSeq
          }

        override def findReferencing(complexFoodId: ComplexFoodId): DBIO[Seq[Tables.ComplexIngredientRow]] =
          fromIO {
            map.values
              .filter(_.complexFoodId.transformInto[ComplexFoodId] == complexFoodId)
              .toSeq
          }

      }

    def instanceFrom(contents: Seq[(UserId, RecipeId, ComplexIngredient)]): db.daos.complexIngredient.DAO =
      instance(
        contents.map { case (userId, recipeId, complexIngredient) =>
          ComplexIngredientKey(userId, recipeId, complexIngredient.complexFoodId) ->
            services.complex.ingredient.ComplexIngredient
              .TransformableToDB(userId, complexIngredient)
              .transformInto[Tables.ComplexIngredientRow]
        }
      )

  }

  object Ingredient {

    def instance(contents: Seq[(IngredientId, Tables.RecipeIngredientRow)]): db.daos.ingredient.DAO =
      new DAOTestInstance[Tables.RecipeIngredientRow, IngredientId](
        contents
      ) with db.daos.ingredient.DAO {

        override def findAllFor(recipeIds: Seq[RecipeId]): DBIO[Seq[Tables.RecipeIngredientRow]] =
          fromIO {
            map.values.collect {
              case ingredient if recipeIds.contains(ingredient.recipeId.transformInto[RecipeId]) => ingredient
            }.toList
          }

      }

    def instanceFrom(contents: Seq[(UserId, RecipeId, Ingredient)]): db.daos.ingredient.DAO =
      instance(
        contents.map { case (userId, recipeId, ingredient) =>
          ingredient.id -> (ingredient, recipeId, userId).transformInto[Tables.RecipeIngredientRow]
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
              .filter { case (key, meal) =>
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

        override def allOf(userId: UserId, mealIds: Seq[MealId]): DBIO[Seq[Tables.MealRow]] =
          fromIO {
            map.view
              .filterKeys { key => key.userId == userId && mealIds.contains(key.mealId) }
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

        override def findAllFor(
            mealIds: Seq[MealId]
        )(implicit ec: ExecutionContext): DBIO[Map[MealId, Seq[Tables.MealEntryRow]]] =
          fromIO {
            map.values
              .filter(meal => mealIds.contains(meal.mealId.transformInto[MealId]))
              .groupBy(_.mealId.transformInto[MealId])
              .view
              .mapValues(_.toSeq)
              .toMap
          }

      }

    def instanceFrom(contents: Seq[(UserId, MealId, MealEntry)]): db.daos.mealEntry.DAO =
      instance(
        contents.map { case (userId, mealId, mealEntry) =>
          mealEntry.id -> services.meal.MealEntry
            .TransformableToDB(userId, mealId, mealEntry)
            .transformInto[Tables.MealEntryRow]
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

        override def allOf(userId: UserId, ids: Seq[RecipeId]): DBIO[Seq[Tables.RecipeRow]] =
          fromIO {
            map.values
              .filter(recipe =>
                recipe.userId.transformInto[UserId] == userId && ids.contains(recipe.id.transformInto[RecipeId])
              )
              .toList
          }

      }

    def instanceFrom(contents: Seq[(UserId, Recipe)]): db.daos.recipe.DAO =
      instance(
        contents.map { case (userId, recipe) =>
          RecipeKey(userId, recipe.id) -> services.recipe.Recipe
            .TransformableToDB(userId, recipe)
            .transformInto[Tables.RecipeRow]
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

        override def allOf(userId: UserId, referenceMapIds: Seq[ReferenceMapId]): DBIO[Seq[Tables.ReferenceMapRow]] =
          fromIO {
            map.view
              .filterKeys(key => key.userId == userId && referenceMapIds.contains(key.referenceMapId))
              .values
              .toList
          }

      }

    def instanceFrom(contents: Seq[(UserId, ReferenceMap)]): db.daos.referenceMap.DAO =
      instance(
        contents.map { case (userId, referenceMap) =>
          ReferenceMapKey(userId, referenceMap.id) ->
            services.reference.ReferenceMap
              .TransformableToDB(userId, referenceMap)
              .transformInto[Tables.ReferenceMapRow]
        }
      )

  }

  object ReferenceMapEntry {

    def instance(contents: Seq[(ReferenceMapEntryKey, Tables.ReferenceEntryRow)]): db.daos.referenceMapEntry.DAO =
      new DAOTestInstance[Tables.ReferenceEntryRow, ReferenceMapEntryKey](
        contents
      ) with db.daos.referenceMapEntry.DAO {

        override def findAllFor(referenceMapIds: Seq[ReferenceMapId]): DBIO[Seq[Tables.ReferenceEntryRow]] =
          fromIO {
            map.view
              .filterKeys(key => referenceMapIds.contains(key.referenceMapId))
              .values
              .toList
          }

      }

    def instanceFrom(contents: Seq[(UserId, ReferenceMapId, ReferenceEntry)]): db.daos.referenceMapEntry.DAO =
      instance(
        contents.map { case (userId, referenceMapId, referenceEntry) =>
          ReferenceMapEntryKey(userId, referenceMapId, referenceEntry.nutrientCode) ->
            services.reference.ReferenceEntry
              .TransformableToDB(userId, referenceMapId, referenceEntry)
              .transformInto[Tables.ReferenceEntryRow]
        }
      )

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

        override def deleteAllBefore(userId: UserId, date: sql.Date): DBIO[Int] =
          fromIO {
            map
              .collect { case (key, row) if key.userId == userId && row.createdAt.before(date) => key }
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
