package services.recipe

import cats.syntax.traverse._
import db.DAOTestInstance
import db.generated.Tables
import io.scalaland.chimney.dsl._
import org.scalacheck.Prop.AnyOperators
import org.scalacheck.Properties
import services.DBTestUtil
import slick.dbio.DBIO
import slick.jdbc.PostgresProfile.api._
import utils.DBIOUtil.instances._
import utils.TransformerUtils.Implicits._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.chaining._

object AllFoodsProperties extends Properties("All foods") {

  private def oldImplementation: DBIO[Seq[Food]] =
    for {
      foods <- Tables.FoodName.result
      withMeasure <- foods.traverse { food =>
        Tables.ConversionFactor
          .filter(cf => cf.foodId === food.foodId)
          .map(_.measureId)
          .result
          .flatMap(measureIds =>
            Tables.MeasureName
              .filter(_.measureId.inSetBind(AmountUnit.hundredGrams.transformInto[Int] +: measureIds))
              .result
              .map(ms => food -> ms.toList)
          ): DBIO[(Tables.FoodNameRow, List[Tables.MeasureNameRow])]
      }
    } yield withMeasure.map(_.transformInto[Food])

  property("Constant is computed correctly") = {
    val oldFoods = oldImplementation.pipe(DBTestUtil.dbRun).pipe(DBTestUtil.await(_))
    val newFoods = new services.recipe.Live.Companion(
      recipeDao = DAOTestInstance.Recipe.instanceFrom(Seq.empty),
      ingredientDao = DAOTestInstance.Ingredient.instance(Seq.empty),
      generalTableConstants = DBTestUtil.generalTableConstants
    ).allFoods.pipe(DBTestUtil.dbRun).pipe(DBTestUtil.await(_))

    def sort(foods: Seq[Food]): Seq[Food] =
      foods.sortBy(_.id).map(food => food.copy(measures = food.measures.sortBy(_.id)))

    sort(newFoods) ?= sort(oldFoods)
  }
}
