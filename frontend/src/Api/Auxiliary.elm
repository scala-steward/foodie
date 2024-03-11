module Api.Auxiliary exposing (..)

import Uuid exposing (Uuid)


type alias RecipeId =
    Uuid


type alias IngredientId =
    Uuid


type alias MeasureId =
    Int


type alias FoodId =
    Int


type alias MealId =
    Uuid


type alias MealEntryId =
    Uuid


type alias NutrientCode =
    Int


type alias UserId =
    Uuid


type alias ProfileId =
    Uuid


type alias JWT =
    String


type alias ReferenceMapId =
    Uuid


type alias ComplexFoodId =
    RecipeId


type alias ComplexIngredientId =
    RecipeId
