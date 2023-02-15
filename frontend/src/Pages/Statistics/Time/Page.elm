module Pages.Statistics.Time.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (FoodId, JWT, MealId, NutrientCode, RecipeId, ReferenceMapId)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil as StatisticsUtil exposing (ReferenceNutrientTree, StatisticsEvaluation)
import Pages.Statistics.Time.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , requestInterval : RequestInterval
    , stats : Stats
    , statisticsEvaluation : StatisticsEvaluation
    , pagination : Pagination
    , fetching : Bool
    , variant : Page
    }


type alias Initial =
    { jwt : JWT
    , referenceTrees : Maybe (DictList ReferenceMapId ReferenceNutrientTree)
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceTrees = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration



-- todo: remove later


defaultStats : Stats
defaultStats =
    { meals = []
    , nutrients = []
    , weightInGrams = 0
    }


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\referenceTrees ->
            { jwt = i.jwt
            , requestInterval = RequestIntervalLens.default
            , stats = defaultStats
            , statisticsEvaluation = StatisticsUtil.initialWith referenceTrees
            , pagination = Pagination.initial
            , fetching = False
            , variant = StatisticsVariant.Time
            }
        )
        i.referenceTrees


lenses :
    { initial : { referenceTrees : Lens Initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree)) }
    , main :
        { requestInterval : Lens Main RequestInterval
        , from : Lens Main (Maybe Date)
        , to : Lens Main (Maybe Date)
        , stats : Lens Main Stats
        , statisticsEvaluation : Lens Main StatisticsEvaluation
        , pagination : Lens Main Pagination
        , fetching : Lens Main Bool
        }
    }
lenses =
    let
        requestInterval =
            Lens .requestInterval (\b a -> { a | requestInterval = b })
    in
    { initial =
        { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b }) }
    , main =
        { requestInterval = requestInterval
        , from = requestInterval |> Compose.lensWithLens RequestIntervalLens.from
        , to = requestInterval |> Compose.lensWithLens RequestIntervalLens.to
        , stats = Lens .stats (\b a -> { a | stats = b })
        , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        , fetching = Lens .fetching (\b a -> { a | fetching = b })
        }
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
