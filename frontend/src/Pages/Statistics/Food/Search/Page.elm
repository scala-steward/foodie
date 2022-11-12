module Pages.Statistics.Food.Search.Page exposing (..)

import Api.Types.Food exposing (Food)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Food.Search.Pagination exposing (Pagination)
import Pages.Statistics.Food.Search.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , foods : List Food
    , foodsSearchString : String
    , initialization : Initialization Status
    , pagination : Pagination
    }


lenses :
    { foods : Lens Model (List Food)
    , foodsSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { foods = Lens .foods (\b a -> { a | foods = b })
    , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetSearchString String
    | SetFoodsPagination Pagination
    | GotFetchFoodsResponse (Result Error (List Food))
    | UpdateFoods String
