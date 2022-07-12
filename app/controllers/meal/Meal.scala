package controllers.meal

import io.circe.generic.JsonCodec

import java.time.Instant
import java.util.UUID

@JsonCodec
case class Meal(
    id: UUID,
    date: Instant,
    recipeId: UUID,
    amount: BigDecimal
)
