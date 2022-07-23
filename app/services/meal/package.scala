package services

import shapeless.tag.@@

import java.util.UUID

package object meal {
  sealed trait MealTag

  type MealId = UUID @@ MealTag

  sealed trait MealEntryTag

  type MealEntryId = UUID @@ MealEntryTag

}
