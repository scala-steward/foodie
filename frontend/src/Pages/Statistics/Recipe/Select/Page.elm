module Pages.Statistics.Recipe.Select.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (RecipeId, ReferenceMapId)
import Api.Types.Recipe exposing (Recipe)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Recipe.Select.Status exposing (Status)
import Pages.Statistics.StatisticsUtil exposing (StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , recipe : Recipe
    , recipeStats : TotalOnlyStats
    , statisticsEvaluation : StatisticsEvaluation
    , initialization : Initialization Status
    , variant : Page
    }


lenses :
    { recipe : Lens Model Recipe
    , recipeStats : Lens Model TotalOnlyStats
    , statisticsEvaluation : Lens Model StatisticsEvaluation
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { recipe = Lens .recipe (\b a -> { a | recipe = b })
    , recipeStats = Lens .recipeStats (\b a -> { a | recipeStats = b })
    , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , recipeId : RecipeId
    }


type Msg
    = GotFetchStatsResponse (Result Error TotalOnlyStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchRecipeResponse (Result Error Recipe)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
