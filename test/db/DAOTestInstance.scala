package db

import db.daos.complexIngredient.ComplexIngredientKey
import db.daos.meal.MealKey
import db.daos.recipe.RecipeKey
import db.daos.referenceMap.ReferenceMapKey
import db.daos.referenceMapEntry.ReferenceMapEntryKey
import db.daos.session.SessionKey
import db.generated.Tables
import slick.jdbc.PostgresProfile.api._

import scala.collection.mutable
import scala.concurrent.ExecutionContext
import utils.TransformerUtils.Implicits._
import io.scalaland.chimney.dsl._
import services.common.RequestInterval
import util.DateUtil
import utils.date.Date

abstract class DAOTestInstance[Content, Key](
    contents: Seq[(Key, Content)],
    override val keyOf: Content => Key
) extends DAOActions[Content, Key] {

  private val map: mutable.Map[Key, Content] = mutable.Map.from(contents)

  override def find(key: Key): DBIO[Option[Content]] = DBIO.successful(map.get(key))

  override def delete(key: Key): DBIO[Int] = DBIO.successful(map.remove(key).fold(0)(_ => 1))

  override def insert(content: Content): DBIO[Content] =
    DBIO.successful {
      map.update(keyOf(content), content)
      content
    }

  override def insertAll(contents: Seq[Content]): DBIO[Seq[Content]] =
    DBIO.successful {
      map.addAll(contents.map(content => keyOf(content) -> content))
      contents
    }

  override def update(value: Content)(implicit ec: ExecutionContext): DBIO[Boolean] =
    DBIO.successful {
      map.update(keyOf(value), value)
      true
    }

  override def exists(key: Key): DBIO[Boolean] =
    DBIO.successful(
      map.contains(key)
    )

}

object DAOTestInstance {

  object ComplexFood {

    def instance(contents: Seq[(RecipeId, Tables.ComplexFoodRow)]): db.daos.complexFood.DAO =
      new DAOTestInstance[Tables.ComplexFoodRow, RecipeId](
        contents,
        _.recipeId.transformInto[RecipeId]
      ) with db.daos.complexFood.DAO {

        override def findByKeys(keys: Seq[RecipeId]): DBIO[Seq[Tables.ComplexFoodRow]] =
          DBIO.successful {
            map.collect {
              case (recipeId, complexFood) if keys.contains(recipeId) => complexFood
            }.toList
          }

      }

  }

  object ComplexIngredient {

    def instance(contents: Seq[(ComplexIngredientKey, Tables.ComplexIngredientRow)]): db.daos.complexIngredient.DAO =
      new DAOTestInstance[Tables.ComplexIngredientRow, ComplexIngredientKey](
        contents,
        ComplexIngredientKey.of
      ) with db.daos.complexIngredient.DAO {

        override def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.ComplexIngredientRow]] =
          DBIO.successful {
            map.view
              .filterKeys(_.recipeId == recipeId)
              .values
              .toSeq
          }

      }

  }

  object Ingredient {

    def instance(contents: Seq[(IngredientId, Tables.RecipeIngredientRow)]): db.daos.ingredient.DAO =
      new DAOTestInstance[Tables.RecipeIngredientRow, IngredientId](
        contents,
        _.id.transformInto[IngredientId]
      ) with db.daos.ingredient.DAO {

        override def findAllFor(recipeId: RecipeId): DBIO[Seq[Tables.RecipeIngredientRow]] =
          DBIO.successful {
            map.values.collect {
              case ingredient if ingredient.recipeId.transformInto[RecipeId] == recipeId => ingredient
            }.toList
          }

      }

  }

  object Meal {

    def instance(contents: Seq[(MealKey, Tables.MealRow)]): db.daos.meal.DAO =
      new DAOTestInstance[Tables.MealRow, MealKey](
        contents,
        MealKey.of
      ) with db.daos.meal.DAO {

        override def allInInterval(userId: UserId, requestInterval: RequestInterval): DBIO[Seq[Tables.MealRow]] =
          DBIO.successful {
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

  }

  object MealEntry {

    def instance(contents: Seq[(MealEntryId, Tables.MealEntryRow)]): db.daos.mealEntry.DAO =
      new DAOTestInstance[Tables.MealEntryRow, MealEntryId](
        contents,
        _.id.transformInto[MealEntryId]
      ) with db.daos.mealEntry.DAO {

        override def findAllFor(mealId: MealId): DBIO[Seq[Tables.MealEntryRow]] =
          DBIO.successful {
            map.values
              .filter(_.mealId.transformInto[MealId] == mealId)
              .toList
          }

      }

  }

  object Recipe {

    def instance(contents: Seq[(RecipeKey, Tables.RecipeRow)]): db.daos.recipe.DAO =
      new DAOTestInstance[Tables.RecipeRow, RecipeKey](
        contents,
        RecipeKey.of
      ) with db.daos.recipe.DAO {

        override def findAllFor(userId: UserId): DBIO[Seq[Tables.RecipeRow]] =
          DBIO.successful {
            map.values
              .filter(_.userId.transformInto[UserId] == userId)
              .toList
          }

      }

  }

  object ReferenceMap {

    def instance(contents: Seq[(ReferenceMapKey, Tables.ReferenceMapRow)]): db.daos.referenceMap.DAO =
      new DAOTestInstance[Tables.ReferenceMapRow, ReferenceMapKey](
        contents,
        ReferenceMapKey.of
      ) with db.daos.referenceMap.DAO {

        override def findAllFor(userId: UserId): DBIO[Seq[Tables.ReferenceMapRow]] =
          DBIO.successful {
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
        contents,
        ReferenceMapEntryKey.of
      ) with db.daos.referenceMapEntry.DAO {

        override def findAllFor(referenceMapId: ReferenceMapId): DBIO[Seq[Tables.ReferenceEntryRow]] =
          DBIO.successful {
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
        contents,
        SessionKey.of
      ) with db.daos.session.DAO {

        override def deleteAllFor(userId: UserId): DBIO[Int] =
          DBIO.successful {
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
        contents,
        _.id.transformInto[UserId]
      ) with db.daos.user.DAO {

        override def findByNickname(nickname: String): DBIO[Seq[Tables.UserRow]] =
          DBIO.successful {
            map.values
              .filter(_.nickname == nickname)
              .toList
          }

        override def findByIdentifier(identifier: String): DBIO[Seq[Tables.UserRow]] =
          DBIO.successful {
            map.values
              .filter(user => user.email == identifier || user.nickname == identifier)
              .toList
          }

      }

  }

}
