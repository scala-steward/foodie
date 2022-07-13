package controllers.meal

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class MealEntry(
    recipeId: UUID,
    amount: BigDecimal
)
