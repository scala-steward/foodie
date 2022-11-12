module Pages.Statistics.Time.Page exposing (..)

import Addresses.StatisticsVariant exposing (StatisticsVariant)
import Api.Auxiliary exposing (FoodId, MealId, NutrientCode, RecipeId, ReferenceMapId)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil exposing (StatisticsEvaluation)
import Pages.Statistics.Time.Pagination exposing (Pagination)
import Pages.Statistics.Time.Status exposing (Status)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , requestInterval : RequestInterval
    , stats : Stats
    , statisticsEvaluation : StatisticsEvaluation
    , initialization : Initialization Status
    , pagination : Pagination
    , fetching : Bool
    , variant : StatisticsVariant
    }


lenses :
    { requestInterval : Lens Model RequestInterval
    , from : Lens Model (Maybe Date)
    , to : Lens Model (Maybe Date)
    , stats : Lens Model Stats
    , statisticsEvaluation : Lens Model StatisticsEvaluation
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    , fetching : Lens Model Bool
    }
lenses =
    let
        requestInterval =
            Lens .requestInterval (\b a -> { a | requestInterval = b })
    in
    { requestInterval = requestInterval
    , from = requestInterval |> Compose.lensWithLens RequestIntervalLens.from
    , to = requestInterval |> Compose.lensWithLens RequestIntervalLens.to
    , stats = Lens .stats (\b a -> { a | stats = b })
    , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    , fetching = Lens .fetching (\b a -> { a | fetching = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = SetFromDate (Maybe Date)
    | SetToDate (Maybe Date)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | SetPagination Pagination
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
