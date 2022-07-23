package services.meal

import db.generated.Tables
import io.scalaland.chimney.Transformer
import io.scalaland.chimney.dsl.TransformerOps
import services.user.UserId
import utils.SimpleDate
import utils.TransformerUtils.Implicits._

import java.util.UUID

case class Meal(
    id: MealId,
    date: SimpleDate,
    name: Option[String],
    entries: Seq[MealEntry]
)

object Meal {

  case class DBRepresentation(
      mealRow: Tables.MealRow,
      mealEntryRows: Seq[Tables.MealEntryRow]
  )

  implicit val fromRepresentation: Transformer[DBRepresentation, Meal] =
    Transformer
      .define[DBRepresentation, Meal]
      .withFieldComputed(_.id, _.mealRow.id.transformInto[MealId])
      .withFieldComputed(
        _.date,
        r =>
          SimpleDate(
            r.mealRow.consumedOnDate.toLocalDate,
            r.mealRow.consumedOnTime.map(_.toLocalTime)
          )
      )
      .withFieldComputed(_.name, _.mealRow.name)
      .withFieldComputed(_.entries, _.mealEntryRows.map(_.transformInto[MealEntry]))
      .buildTransformer

  implicit val toRepresentation: Transformer[(Meal, UserId), DBRepresentation] = {
    case (meal, userId) =>
      DBRepresentation(
        mealRow = Tables.MealRow(
          id = meal.id.transformInto[UUID],
          userId = userId.transformInto[UUID],
          consumedOnDate = meal.date.date.transformInto[java.sql.Date],
          consumedOnTime = meal.date.time.map(_.transformInto[java.sql.Time]),
          name = meal.name
        ),
        mealEntryRows = meal.entries.map(me => (me, meal.id).transformInto[Tables.MealEntryRow])
      )
  }

}
