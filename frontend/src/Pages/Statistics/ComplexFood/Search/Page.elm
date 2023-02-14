module Pages.Statistics.ComplexFood.Search.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (JWT)
import Api.Types.ComplexFood exposing (ComplexFood)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.ComplexFood.Search.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , complexFoods : List ComplexFood
    , complexFoodsSearchString : String
    , pagination : Pagination
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , complexFoods : Maybe (List ComplexFood)
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , complexFoods = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\complexFoods ->
            { jwt = i.jwt
            , complexFoods = complexFoods
            , complexFoodsSearchString = ""
            , pagination = Pagination.initial
            , variant = StatisticsVariant.ComplexFood
            }
        )
        i.complexFoods


lenses :
    { initial :
        { complexFoods : Lens Initial (Maybe (List ComplexFood))
        }
    , main :
        { complexFoods : Lens Main (List ComplexFood)
        , complexFoodsSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial =
        { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
        }
    , main =
        { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
        , complexFoodsSearchString = Lens .complexFoodsSearchString (\b a -> { a | complexFoodsSearchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetSearchString String
    | SetComplexFoodsPagination Pagination
    | GotFetchComplexFoodsResponse (Result Error (List ComplexFood))
