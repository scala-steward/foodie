package controllers.meal

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class MealEntry(
    id: UUID,
    recipeId: UUID,
    factor: BigDecimal
)
