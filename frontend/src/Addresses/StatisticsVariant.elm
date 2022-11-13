module Addresses.StatisticsVariant exposing (..)

import Url.Builder


type Page
    = Food
    | Recipe
    | Meal
    | Time


foodBackend : String
foodBackend =
    "food"


foodFrontend : String
foodFrontend =
    "ingredient"


recipe : String
recipe =
    "recipe"


meal : String
meal =
    "meal"


addressSuffix : Page -> String
addressSuffix page =
    let
        suffix =
            case page of
                Food ->
                    foodFrontend

                Recipe ->
                    recipe

                Meal ->
                    meal

                Time ->
                    ""
    in
    Url.Builder.relative [ "statistics", suffix ] []


nameOfPage : Page -> String
nameOfPage page =
    case page of
        {- From a user perspective there is no need to differentiate between
           'food' and 'ingredient', hence we only use 'ingredient'.
           Internally, an ingredient is a link between a recipe and a food.
        -}
        Food ->
            "Ingredient"

        Recipe ->
            "Recipe"

        Meal ->
            "Meal"

        Time ->
            "Over time"
