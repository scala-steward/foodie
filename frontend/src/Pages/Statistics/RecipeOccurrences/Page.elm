module Pages.Statistics.RecipeOccurrences.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (JWT)
import Api.Types.RecipeOccurrence exposing (RecipeOccurrence)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.RecipeOccurrences.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , recipeOccurrences : List RecipeOccurrence
    , recipesSearchString : String
    , pagination : Pagination
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , recipeOccurrences : Maybe (List RecipeOccurrence)
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , recipeOccurrences = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\recipeOccurrences ->
            { jwt = i.jwt
            , recipeOccurrences = recipeOccurrences
            , recipesSearchString = ""
            , pagination = Pagination.initial
            , variant = StatisticsVariant.RecipeOccurrences
            }
        )
        i.recipeOccurrences


lenses :
    { initial : { recipeOccurrences : Lens Initial (Maybe (List RecipeOccurrence)) }
    , main :
        { recipeOccurrences : Lens Main (List RecipeOccurrence)
        , recipesSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial = { recipeOccurrences = Lens .recipeOccurrences (\b a -> { a | recipeOccurrences = b }) }
    , main =
        { recipeOccurrences = Lens .recipeOccurrences (\b a -> { a | recipeOccurrences = b })
        , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg

-- todo: Add sorting logic
type LogicMsg
    = SetSearchString String
    | SetRecipeOccurrencesPagination Pagination
    | GotFetchRecipeOccurrencesResponse (Result Error (List RecipeOccurrence))
