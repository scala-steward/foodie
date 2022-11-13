module Pages.Statistics.Recipe.Search.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Types.Recipe exposing (Recipe)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Recipe.Search.Pagination exposing (Pagination)
import Pages.Statistics.Recipe.Search.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipes : List Recipe
    , recipesSearchString : String
    , initialization : Initialization Status
    , pagination : Pagination
    , variant : Page
    }


lenses :
    { recipes : Lens Model (List Recipe)
    , recipesSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { recipes = Lens .recipes (\b a -> { a | recipes = b })
    , recipesSearchString = Lens .recipesSearchString (\b a -> { a | recipesSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetSearchString String
    | SetRecipesPagination Pagination
    | GotFetchRecipesResponse (Result Error (List Recipe))
    | UpdateRecipes String
