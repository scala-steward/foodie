module Addresses.StatisticsVariant exposing (..)

import Api.Auxiliary exposing (FoodId, MealId, RecipeId)
import Maybe.Extra


type StatisticsVariant
    = Food (Maybe FoodId)
    | Recipe (Maybe RecipeId)
    | Meal (Maybe MealId)
    | Time



-- todo: Check use


toString : StatisticsVariant -> List String
toString variant =
    case variant of
        Food maybeFoodId ->
            food :: (maybeFoodId |> Maybe.map String.fromInt |> Maybe.Extra.toList)

        Recipe maybeRecipeId ->
            recipe :: (maybeRecipeId |> Maybe.Extra.toList)

        Meal maybeMealId ->
            meal :: (maybeMealId |> Maybe.Extra.toList)

        Time ->
            []


food : String
food =
    "food"


recipe : String
recipe =
    "recipe"


meal : String
meal =
    "meal"
