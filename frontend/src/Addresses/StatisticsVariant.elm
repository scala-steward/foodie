module Addresses.StatisticsVariant exposing (..)


type Page
    = Food Parameter
    | Recipe Parameter
    | Meal Parameter
    | Time


type Parameter
    = None
    | Some


food : String
food =
    "food"


recipe : String
recipe =
    "recipe"


meal : String
meal =
    "meal"


addressSuffix : Page -> String
addressSuffix page =
    case page of
        Food _ ->
            food

        Recipe _ ->
            recipe

        Meal _ ->
            meal

        Time ->
            ""


nameOfPage : Page -> String
nameOfPage page =
    case page of
        Food _ ->
            "Food"

        Recipe _ ->
            "Recipe"

        Meal _ ->
            "Meal"

        Time ->
            "Over time"
