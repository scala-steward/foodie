module Pages.Statistics.Time.Page exposing (..)

import Addresses.StatisticsVariant as StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (FoodId, JWT, MealId, NutrientCode, ProfileId, RecipeId, ReferenceMapId)
import Api.Lenses.RequestIntervalLens as RequestIntervalLens
import Api.Types.Date exposing (Date)
import Api.Types.Profile exposing (Profile)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.RequestInterval exposing (RequestInterval)
import Api.Types.Stats exposing (Stats)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Statistics.StatisticsUtil as StatisticsUtil exposing (ReferenceNutrientTree, StatisticsEvaluation)
import Pages.Statistics.Time.Pagination as Pagination exposing (Pagination)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList as DictList exposing (DictList)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , requestInterval : RequestInterval
    , stats : Stats
    , statisticsEvaluation : StatisticsEvaluation
    , profiles : DictList ProfileId Profile
    , selectedProfile : Maybe Profile
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
    , profiles : Maybe (List Profile)
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceTrees = Nothing
    , profiles = Nothing
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
    Maybe.map2
        (\referenceTrees profiles ->
            { jwt = i.jwt
            , requestInterval = RequestIntervalLens.default
            , stats = defaultStats
            , statisticsEvaluation = StatisticsUtil.initialWith referenceTrees
            , profiles = DictList.fromListWithKey .id profiles
            , selectedProfile = Nothing
            , pagination = Pagination.initial
            , status = Select
            , variant = StatisticsVariant.Time
            }
        )
        i.referenceTrees
        i.profiles


lenses :
    { initial :
        { referenceTrees : Lens Initial (Maybe (DictList ReferenceMapId ReferenceNutrientTree))
        , profiles : Lens Initial (Maybe (List Profile))
        }
    , main :
        { requestInterval : Lens Main RequestInterval
        , from : Lens Main (Maybe Date)
        , to : Lens Main (Maybe Date)
        , stats : Lens Main Stats
        , statisticsEvaluation : Lens Main StatisticsEvaluation
        , profiles : Lens Main (DictList ProfileId Profile)
        , selectedProfile : Lens Main (Maybe Profile)
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
        { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
        , profiles = Lens .profiles (\b a -> { a | profiles = b })
        }
    , main =
        { requestInterval = requestInterval
        , from = requestInterval |> Compose.lensWithLens RequestIntervalLens.from
        , to = requestInterval |> Compose.lensWithLens RequestIntervalLens.to
        , stats = Lens .stats (\b a -> { a | stats = b })
        , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
        , profiles = Lens .profiles (\b a -> { a | profiles = b })
        , selectedProfile = Lens .selectedProfile (\b a -> { a | selectedProfile = b })
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
    | SelectProfile (Maybe ProfileId)
    | FetchStats
    | GotFetchStatsResponse (Result Error Stats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchProfilesResponse (Result Error (List Profile))
    | SetPagination Pagination
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
