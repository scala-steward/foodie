package services.meal

import db.generated.Tables
import io.scalaland.chimney.Transformer
import shapeless.tag.@@
import io.scalaland.chimney.dsl.TransformerOps
import utils.IdUtils.Implicits._

import java.time.{ LocalDate, LocalTime }
import java.util.UUID

case class Meal(
    id: MealId,
    date: LocalDate,
    time: Option[LocalTime],
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
      .withFieldComputed(_.date, _.mealRow.consumedOnDate.toLocalDate)
      .withFieldComputed(_.time, _.mealRow.consumedOnTime.map(_.toLocalTime))
      .withFieldComputed(_.name, _.mealRow.name)
      .withFieldComputed(_.entries, _.mealEntryRows.map(_.transformInto[MealEntry]))
      .buildTransformer

}
