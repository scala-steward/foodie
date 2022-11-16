module Pages.Statistics.Meal.Search.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Types.Meal exposing (Meal)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Meal.Search.Pagination exposing (Pagination)
import Pages.Statistics.Meal.Search.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , meals : List Meal
    , mealsSearchString : String
    , initialization : Initialization Status
    , pagination : Pagination
    , variant : Page
    }


lenses :
    { meals : Lens Model (List Meal)
    , mealsSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { meals = Lens .meals (\b a -> { a | meals = b })
    , mealsSearchString = Lens .mealsSearchString (\b a -> { a | mealsSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetSearchString String
    | SetMealsPagination Pagination
    | GotFetchMealsResponse (Result Error (List Meal))
    | UpdateMeals String
