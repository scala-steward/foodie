module Pages.Statistics.ComplexFood.Search.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Types.ComplexFood exposing (ComplexFood)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.ComplexFood.Search.Pagination exposing (Pagination)
import Pages.Statistics.ComplexFood.Search.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , complexFoods : List ComplexFood
    , complexFoodsSearchString : String
    , initialization : Initialization Status
    , pagination : Pagination
    , variant : Page
    }

lenses :
    { complexFoods : Lens Model (List ComplexFood)
    , complexFoodsSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    , complexFoodsSearchString = Lens .complexFoodsSearchString (\b a -> { a | complexFoodsSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetSearchString String
    | SetComplexFoodsPagination Pagination
    | GotFetchComplexFoodsResponse (Result Error (List ComplexFood))
    | UpdateComplexFoods String
