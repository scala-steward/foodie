module Pages.Statistics.Recipe.Search.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (JWT)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Recipe.Search.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipes : List Recipe
    , recipesSearchString : String
    , pagination : Pagination
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , recipes : Maybe (List Recipe)
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , recipes = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\recipes ->
            { jwt = i.jwt
            , recipes = recipes
            , recipesSearchString = ""
            , pagination = Pagination.initial
            , variant = StatisticsVariant.Recipe
            }
        )
        i.recipes


lenses :
    { initial : { recipes : Lens Initial (Maybe (List Recipe)) }
    , main :
        { recipes : Lens Main (List Recipe)
        , recipesSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial = { recipes = Lens .recipes (\b a -> { a | recipes = b }) }
    , main =
        { recipes = Lens .recipes (\b a -> { a | recipes = b })
        , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
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
    | SetRecipesPagination Pagination
    | GotFetchRecipesResponse (Result Error (List Recipe))
