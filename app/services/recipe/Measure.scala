package services.recipe

import shapeless.tag.@@

import java.util.UUID

case class Measure(
    id: UUID @@ MeasureId,
    name: String
)
