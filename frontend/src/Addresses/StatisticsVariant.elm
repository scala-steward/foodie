module Addresses.StatisticsVariant exposing (..)

import Url.Builder


type Page
    = Food
    | ComplexFood
    | Recipe
    | Meal
    | Time
    | RecipeOccurrences


food : String
food =
    "food"


complexFood : String
complexFood =
    "complex-food"


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
                    food

                ComplexFood ->
                    complexFood

                Recipe ->
                    recipe

                Meal ->
                    meal

                Time ->
                    ""

                RecipeOccurrences ->
                    "recipe-occurrences"
    in
    Url.Builder.relative [ "statistics", suffix ] []


nameOfPage : Page -> String
nameOfPage page =
    case page of
        Food ->
            "Food"

        ComplexFood ->
            "Complex food"

        Recipe ->
            "Recipe"

        Meal ->
            "Meal"

        Time ->
            "Over time"

        RecipeOccurrences ->
            "Recipe occurrences"
