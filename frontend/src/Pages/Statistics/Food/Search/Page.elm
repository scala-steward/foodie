module Pages.Statistics.Food.Search.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (JWT)
import Api.Types.Food exposing (Food)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Food.Search.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , foods : List Food
    , foodsSearchString : String
    , pagination : Pagination
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , foods : Maybe (List Food)
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , foods = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\foods ->
            { jwt = i.jwt
            , foods = foods
            , foodsSearchString = ""
            , pagination = Pagination.initial
            , variant = StatisticsVariant.Food
            }
        )
        i.foods


lenses :
    { initial :
        { foods : Lens Initial (Maybe (List Food))
        }
    , main :
        { foods : Lens Main (List Food)
        , foodsSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial = { foods = Lens .foods (\b a -> { a | foods = b }) }
    , main =
        { foods = Lens .foods (\b a -> { a | foods = b })
        , foodsSearchString = Lens .foodsSearchString (\b a -> { a | foodsSearchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = SetSearchString String
    | SetFoodsPagination Pagination
    | GotFetchFoodsResponse (Result Error (List Food))
    | UpdateFoods String
