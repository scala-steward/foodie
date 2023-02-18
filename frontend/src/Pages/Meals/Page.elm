module Pages.Meals.Page exposing (..)

import Api.Auxiliary exposing (JWT, MealId)
import Api.Types.Meal exposing (Meal)
import Monocle.Lens exposing (Lens)
import Pages.Meals.MealCreationClientInput exposing (MealCreationClientInput)
import Pages.Meals.MealUpdateClientInput exposing (MealUpdateClientInput)
import Pages.Meals.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , meals : MealStateMap
    , mealToAdd : Maybe MealCreationClientInput
    , searchString : String
    , pagination : Pagination
    }


type alias Initial =
    { jwt : JWT
    , meals : Maybe MealStateMap
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { meals = Nothing
    , jwt = authorizedAccess.jwt
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    i.meals
        |> Maybe.map
            (\meals ->
                { jwt = i.jwt
                , meals = meals
                , mealToAdd = Nothing
                , searchString = ""
                , pagination = Pagination.initial
                }
            )


type alias MealState =
    Editing Meal MealUpdateClientInput


type alias MealStateMap =
    DictList MealId MealState


lenses :
    { initial : { meals : Lens Initial (Maybe MealStateMap) }
    , main :
        { meals : Lens Main MealStateMap
        , mealToAdd : Lens Main (Maybe MealCreationClientInput)
        , searchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial = { meals = Lens .meals (\b a -> { a | meals = b }) }
    , main =
        { meals = Lens .meals (\b a -> { a | meals = b })
        , mealToAdd = Lens .mealToAdd (\b a -> { a | mealToAdd = b })
        , searchString = Lens .searchString (\b a -> { a | searchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = UpdateMealCreation (Maybe MealCreationClientInput)
    | CreateMeal
    | GotCreateMealResponse (Result Error Meal)
    | UpdateMeal MealUpdateClientInput
    | SaveMealEdit MealId
    | GotSaveMealResponse (Result Error Meal)
    | EnterEditMeal MealId
    | ExitEditMealAt MealId
    | RequestDeleteMeal MealId
    | ConfirmDeleteMeal MealId
    | CancelDeleteMeal MealId
    | GotDeleteMealResponse MealId (Result Error ())
    | GotFetchMealsResponse (Result Error (List Meal))
    | SetPagination Pagination
    | SetSearchString String
