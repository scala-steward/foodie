//package services.meal
//
//import cats.data.EitherT
//import cats.syntax.traverse._
//import config.TestConfiguration
//import errors.{ ErrorContext, ServerError }
//import org.scalacheck.Prop.AnyOperators
//import org.scalacheck.{ Gen, Prop, Properties, Test }
//import services.recipe.RecipeService
//import services.stats.ServiceFunctions
//import services.user.UserService
//import services.{ DBTestUtil, GenUtils, TestUtil }
//
//import scala.concurrent.ExecutionContext.Implicits.global
//import scala.concurrent.Future
//
//object MealServiceProperties extends Properties("Meal service") {
//
//  private val mealService   = TestUtil.injector.instanceOf[MealService]
//  private val userService   = TestUtil.injector.instanceOf[UserService]
//  private val recipeService = TestUtil.injector.instanceOf[RecipeService]
//
//  property("Creation") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealCreationGen() :| "meal creation"
//  ) { (user, mealCreation) =>
//    DBTestUtil.clearDb()
//    val transformer = for {
//      _           <- EitherT.liftF(userService.add(user))
//      createdMeal <- EitherT(mealService.createMeal(user.id, mealCreation))
//      fetchedMeal <- EitherT.fromOptionF(
//        mealService.getMeal(user.id, createdMeal.id),
//        ErrorContext.Meal.NotFound.asServerError
//      )
//    } yield {
//      val expectedMeal = MealCreation.create(createdMeal.id, mealCreation)
//      Prop.all(
//        createdMeal ?= expectedMeal,
//        fetchedMeal ?= expectedMeal
//      )
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Read single") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealCreationGen() :| "meal creation"
//  ) { (user, mealCreation) =>
//    DBTestUtil.clearDb()
//    val transformer = for {
//      _ <- EitherT.liftF(userService.add(user))
//      insertedMeal <- ServiceFunctions.createMeal(mealService)(
//        user.id,
//        MealParameters(
//          mealCreation = mealCreation,
//          mealEntryParameters = List.empty
//        )
//      )
//      fetchedMeal <- EitherT.fromOptionF(
//        mealService.getMeal(user.id, insertedMeal.meal.id),
//        ErrorContext.Meal.NotFound.asServerError
//      )
//    } yield {
//      fetchedMeal ?= insertedMeal.meal
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Read all") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gen.listOf(Gens.mealCreationGen()) :| "meal creations"
//  ) { (user, mealCreations) =>
//    DBTestUtil.clearDb()
//    val transformer = for {
//      _ <- EitherT.liftF(userService.add(user))
//      insertedMeals <- mealCreations.traverse { mealCreation =>
//        ServiceFunctions.createMeal(mealService)(
//          user.id,
//          MealParameters(
//            mealCreation = mealCreation,
//            mealEntryParameters = List.empty
//          )
//        )
//      }
//      fetchedMeals <- EitherT.liftF[Future, ServerError, Seq[Meal]](
//        mealService.allMeals(user.id, RequestInterval(None, None))
//      )
//    } yield {
//      fetchedMeals.sortBy(_.id) ?= insertedMeals.map(_.meal).sortBy(_.id)
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Update") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealCreationGen() :| "meal creation",
//    Gens.mealPreUpdateGen() :| "meal pre-update"
//  ) { (user, mealCreation, preUpdate) =>
//    DBTestUtil.clearDb()
//    val transformer = for {
//      _ <- EitherT.liftF(userService.add(user))
//      insertedMeal <- ServiceFunctions.createMeal(mealService)(
//        user.id,
//        MealParameters(
//          mealCreation = mealCreation,
//          mealEntryParameters = List.empty
//        )
//      )
//      mealUpdate = MealPreUpdate.toUpdate(insertedMeal.meal.id, preUpdate)
//      updatedMeal <- EitherT(mealService.updateMeal(user.id, mealUpdate))
//      fetchedMeal <- EitherT.fromOptionF(
//        mealService.getMeal(user.id, insertedMeal.meal.id),
//        ErrorContext.Meal.NotFound.asServerError
//      )
//    } yield {
//      val expectedMeal = MealUpdate.update(insertedMeal.meal, mealUpdate)
//      Prop.all(
//        updatedMeal ?= expectedMeal,
//        fetchedMeal ?= expectedMeal
//      )
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Delete") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealCreationGen() :| "meal creation"
//  ) { (user, mealCreation) =>
//    DBTestUtil.clearDb()
//    val transformer = for {
//      _ <- EitherT.liftF(userService.add(user))
//      insertedMeal <- ServiceFunctions.createMeal(mealService)(
//        user.id,
//        MealParameters(
//          mealCreation = mealCreation,
//          mealEntryParameters = List.empty
//        )
//      )
//      result  <- EitherT.liftF[Future, ServerError, Boolean](mealService.deleteMeal(user.id, insertedMeal.meal.id))
//      fetched <- EitherT.liftF[Future, ServerError, Option[Meal]](mealService.getMeal(user.id, insertedMeal.meal.id))
//    } yield {
//      Prop.all(
//        Prop(result) :| "Deletion successful",
//        Prop(fetched.isEmpty) :| "Meal should be deleted"
//      )
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Add mealEntry") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gen.listOf(services.recipe.Gens.recipeCreationGen) :| "recipe creations",
//    ,
//    Gens.mealEntryGen :| "mealEntry"
//  ) { (user, mealParameters, mealEntryParameters) =>
//    DBTestUtil.clearDb()
//    Prop.forAll(Gens.mealParametersGen() :| "meal parameters"){ mealParameters =>
//    val transformer = for {
//      _ <- EitherT.liftF(userService.add(user))
//      insertedMeal <- ServiceFunctions.createMeal(mealService)(
//        user.id,
//        mealParameters
//      )
//      mealEntryCreation =
//        MealEntryPreCreation.toCreation(insertedMeal.meal.id, mealEntryParameters.mealEntryPreCreation)
//      mealEntry <- EitherT(mealService.addMealEntry(user.id, mealEntryCreation))
//      mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//        mealService.getMealEntries(user.id, insertedMeal.meal.id)
//      )
//    } yield {
//      val expectedMealEntry = MealEntryCreation.create(mealEntry.id, mealEntryCreation)
//      mealEntries.sortBy(_.id) ?= (expectedMealEntry +: insertedMeal.mealEntries).sortBy(_.id)
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Read mealEntries") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealParametersGen() :| "meal parameters"
//  ) { (user, mealParameters) =>
//    DBTestUtil.clearDb()
//    val transformer = for {
//      _ <- EitherT.liftF(userService.add(user))
//      insertedMeal <- ServiceFunctions.createMeal(mealService)(
//        user.id,
//        mealParameters
//      )
//      mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//        mealService.getMealEntries(user.id, insertedMeal.meal.id)
//      )
//    } yield {
//      mealEntries.sortBy(_.id) ?= insertedMeal.mealEntries.sortBy(_.id)
//    }
//
//    DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Update mealEntry") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealParametersGen() :| "meal parameters"
//  ) { (user, mealParameters) =>
//    DBTestUtil.clearDb()
//    Prop.forAll(
//      Gen
//        .oneOf(mealParameters.mealEntryParameters.zipWithIndex)
//        .flatMap {
//          case (mealEntryParameters, index) =>
//            Gens
//              .mealEntryPreUpdateGen(mealEntryParameters.mealEntryPreCreation.foodId)
//              .map(index -> _)
//        } :| "index and pre-update"
//    ) {
//      case (index, preUpdate) =>
//        val transformer = for {
//          _ <- EitherT.liftF(userService.add(user))
//          insertedMeal <- ServiceFunctions.createMeal(mealService)(
//            user.id,
//            mealParameters
//          )
//          mealEntry       = insertedMeal.mealEntries.apply(index)
//          mealEntryUpdate = MealEntryPreUpdate.toUpdate(mealEntry.id, preUpdate)
//          updatedMealEntry <- EitherT(mealService.updateMealEntry(user.id, mealEntryUpdate))
//          mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//            mealService.getMealEntries(user.id, insertedMeal.meal.id)
//          )
//        } yield {
//          val expectedMealEntry   = MealEntryUpdate.update(mealEntry, mealEntryUpdate)
//          val expectedMealEntries = insertedMeal.mealEntries.updated(index, expectedMealEntry)
//          Prop.all(
//            (updatedMealEntry ?= expectedMealEntry) :| "Update correct",
//            (mealEntries.sortBy(_.id) ?= expectedMealEntries.sortBy(_.id)) :| "MealEntries after update correct"
//          )
//        }
//
//        DBTestUtil.awaitProp(transformer)
//    }
//  }
//
//  property("Delete mealEntry") = Prop.forAll(
//    GenUtils.userWithFixedPassword :| "user",
//    Gens.mealParametersGen() :| "meal parameters"
//  ) { (user, mealParameters) =>
//    DBTestUtil.clearDb()
//    Prop.forAll(
//      Gen
//        .oneOf(mealParameters.mealEntryParameters.zipWithIndex)
//        .map(_._2)
//        :| "index"
//    ) { index =>
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user))
//        insertedMeal <- ServiceFunctions.createMeal(mealService)(
//          user.id,
//          mealParameters
//        )
//        mealEntry = insertedMeal.mealEntries.apply(index)
//        deletionResult <- EitherT.liftF(mealService.removeMealEntry(user.id, mealEntry.id))
//        mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//          mealService.getMealEntries(user.id, insertedMeal.meal.id)
//        )
//      } yield {
//        val expectedMealEntries = insertedMeal.mealEntries.zipWithIndex.filter(_._2 != index).map(_._1)
//        Prop.all(
//          Prop(deletionResult) :| "Deletion successful",
//          (mealEntries.sortBy(_.id) ?= expectedMealEntries.sortBy(_.id)) :| "MealEntries after update correct"
//        )
//      }
//
//      DBTestUtil.awaitProp(transformer)
//    }
//  }
//
//  property("Creation (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealCreationGen() :| "meal creation"
//  ) {
//    case ((user1, user2), mealCreation) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _           <- EitherT.liftF(userService.add(user1))
//        _           <- EitherT.liftF(userService.add(user2))
//        createdMeal <- EitherT(mealService.createMeal(user1.id, mealCreation))
//        fetchedMeal <- EitherT.liftF[Future, ServerError, Option[Meal]](mealService.getMeal(user2.id, createdMeal.id))
//      } yield {
//        Prop(fetchedMeal.isEmpty) :| "Access denied"
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Read single (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealCreationGen() :| "meal creation"
//  ) {
//    case ((user1, user2), mealCreation) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user1))
//        _ <- EitherT.liftF(userService.add(user2))
//        insertedMeal <- ServiceFunctions.createMeal(mealService)(
//          user1.id,
//          MealParameters(
//            mealCreation = mealCreation,
//            mealEntryParameters = List.empty
//          )
//        )
//        fetchedMeal <- EitherT.liftF[Future, ServerError, Option[Meal]](
//          mealService.getMeal(user2.id, insertedMeal.meal.id)
//        )
//      } yield {
//        Prop(fetchedMeal.isEmpty) :| "Access denied"
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Read all (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gen.listOf(Gens.mealCreationGen()) :| "meal creations"
//  ) {
//    case ((user1, user2), mealCreations) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user1))
//        _ <- EitherT.liftF(userService.add(user2))
//        _ <- mealCreations.traverse { mealCreation =>
//          ServiceFunctions.createMeal(mealService)(
//            user1.id,
//            MealParameters(
//              mealCreation = mealCreation,
//              mealEntryParameters = List.empty
//            )
//          )
//        }
//        fetchedMeals <- EitherT.liftF[Future, ServerError, Seq[Meal]](
//          mealService.allMeals(user2.id, RequestInterval(None, None))
//        )
//      } yield {
//        fetchedMeals ?= Seq.empty
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Update (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealCreationGen() :| "meal creation",
//    Gens.mealPreUpdateGen() :| "meal pre-update"
//  ) {
//    case ((user1, user2), mealCreation, preUpdate) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user1))
//        _ <- EitherT.liftF(userService.add(user2))
//        insertedMeal <- ServiceFunctions.createMeal(mealService)(
//          user1.id,
//          MealParameters(
//            mealCreation = mealCreation,
//            mealEntryParameters = List.empty
//          )
//        )
//        mealUpdate = MealPreUpdate.toUpdate(insertedMeal.meal.id, preUpdate)
//        updatedMeal <-
//          EitherT.liftF[Future, ServerError, ServerError.Or[Meal]](mealService.updateMeal(user2.id, mealUpdate))
//      } yield {
//        Prop(updatedMeal.isLeft)
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Delete (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealCreationGen() :| "meal creation"
//  ) {
//    case ((user1, user2), mealCreation) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user1))
//        _ <- EitherT.liftF(userService.add(user2))
//        insertedMeal <- ServiceFunctions.createMeal(mealService)(
//          user1.id,
//          MealParameters(
//            mealCreation = mealCreation,
//            mealEntryParameters = List.empty
//          )
//        )
//        result <- EitherT.liftF[Future, ServerError, Boolean](mealService.deleteMeal(user2.id, insertedMeal.meal.id))
//
//      } yield {
//        Prop(!result) :| "Deletion failed"
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Add mealEntry (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealParametersGen() :| "meal parameters",
//    Gens.mealEntryGen :| "mealEntry"
//  ) {
//    case ((user1, user2), mealParameters, mealEntryParameters) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user1))
//        _ <- EitherT.liftF(userService.add(user2))
//        insertedMeal <- ServiceFunctions.createMeal(mealService)(
//          user1.id,
//          mealParameters
//        )
//        mealEntryCreation =
//          MealEntryPreCreation.toCreation(insertedMeal.meal.id, mealEntryParameters.mealEntryPreCreation)
//        result <- EitherT.liftF(mealService.addMealEntry(user2.id, mealEntryCreation))
//        mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//          mealService.getMealEntries(user1.id, insertedMeal.meal.id)
//        )
//      } yield {
//        Prop.all(
//          Prop(result.isLeft) :| "MealEntry addition failed",
//          mealEntries.sortBy(_.id) ?= insertedMeal.mealEntries.sortBy(_.id)
//        )
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Read mealEntries (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealParametersGen() :| "meal parameters"
//  ) {
//    case ((user1, user2), mealParameters) =>
//      DBTestUtil.clearDb()
//      val transformer = for {
//        _ <- EitherT.liftF(userService.add(user1))
//        insertedMeal <- ServiceFunctions.createMeal(mealService)(
//          user1.id,
//          mealParameters
//        )
//        mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//          mealService.getMealEntries(user2.id, insertedMeal.meal.id)
//        )
//      } yield {
//        mealEntries.sortBy(_.id) ?= List.empty
//      }
//
//      DBTestUtil.awaitProp(transformer)
//  }
//
//  property("Update mealEntry (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealParametersGen() :| "meal parameters"
//  ) {
//    case ((user1, user2), mealParameters) =>
//      DBTestUtil.clearDb()
//      Prop.forAll(
//        Gen
//          .oneOf(mealParameters.mealEntryParameters.zipWithIndex)
//          .flatMap {
//            case (mealEntryParameters, index) =>
//              Gens
//                .mealEntryPreUpdateGen(mealEntryParameters.mealEntryPreCreation.foodId)
//                .map(index -> _)
//          } :| "index and pre-update"
//      ) {
//        case (index, preUpdate) =>
//          val transformer = for {
//            _ <- EitherT.liftF(userService.add(user1))
//            _ <- EitherT.liftF(userService.add(user2))
//            insertedMeal <- ServiceFunctions.createMeal(mealService)(
//              user1.id,
//              mealParameters
//            )
//            mealEntry       = insertedMeal.mealEntries.apply(index)
//            mealEntryUpdate = MealEntryPreUpdate.toUpdate(mealEntry.id, preUpdate)
//            result <- EitherT.liftF(mealService.updateMealEntry(user2.id, mealEntryUpdate))
//            mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//              mealService.getMealEntries(user1.id, insertedMeal.meal.id)
//            )
//          } yield {
//            Prop.all(
//              Prop(result.isLeft) :| "MealEntry update failed",
//              (mealEntries.sortBy(_.id) ?= insertedMeal.mealEntries.sortBy(
//                _.id
//              )) :| "MealEntries after update correct"
//            )
//          }
//
//          DBTestUtil.awaitProp(transformer)
//      }
//  }
//
//  property("Delete mealEntry (wrong user)") = Prop.forAll(
//    GenUtils.twoUsersGen :| "users",
//    Gens.mealParametersGen() :| "meal parameters"
//  ) {
//    case ((user1, user2), mealParameters) =>
//      DBTestUtil.clearDb()
//      Prop.forAll(
//        Gen
//          .oneOf(mealParameters.mealEntryParameters.zipWithIndex)
//          .map(_._2)
//          :| "index"
//      ) { index =>
//        val transformer = for {
//          _ <- EitherT.liftF(userService.add(user1))
//          _ <- EitherT.liftF(userService.add(user2))
//          insertedMeal <- ServiceFunctions.createMeal(mealService)(
//            user1.id,
//            mealParameters
//          )
//          mealEntry = insertedMeal.mealEntries.apply(index)
//          deletionResult <- EitherT.liftF(mealService.removeMealEntry(user2.id, mealEntry.id))
//          mealEntries <- EitherT.liftF[Future, ServerError, List[MealEntry]](
//            mealService.getMealEntries(user1.id, insertedMeal.meal.id)
//          )
//        } yield {
//          val expectedMealEntries = insertedMeal.mealEntries
//          Prop.all(
//            Prop(!deletionResult) :| "MealEntry deletion failed",
//            (mealEntries.sortBy(_.id) ?= expectedMealEntries.sortBy(_.id)) :| "MealEntries after update correct"
//          )
//        }
//
//        DBTestUtil.awaitProp(transformer)
//      }
//  }
//
//  override def overrideParameters(p: Test.Parameters): Test.Parameters =
//    p.withMinSuccessfulTests(TestConfiguration.default.property.minSuccessfulTests)
//
//}
