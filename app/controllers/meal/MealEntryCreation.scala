package controllers.meal

import io.circe.generic.JsonCodec

import java.util.UUID

@JsonCodec
case class MealEntryCreation(
    recipeId: UUID,
    factor: BigDecimal
)
