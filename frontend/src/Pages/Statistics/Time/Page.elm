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
    , status : Status
    , variant : Page
    }


type Status
    = Select
    | Fetch
    | Display


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


{-| Following the Tristate logic this value should not be necessary.
However, stats are loaded _after_ the initialization, which would need nested Tristate logic.
Another alternative is to incorporate the "Initial" approach directly, and make the stats value
optional in the model. This option results in the default values being distributed over
various files, rather than be defined in one place once.
-}
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
            , status = Select
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
        , status : Lens Main Status
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
        , status = Lens .status (\b a -> { a | status = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = SetFromDate (Maybe Date)
    | SetToDate (Maybe Date)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | SetPagination Pagination
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
