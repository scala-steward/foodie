module Pages.Statistics.Food.Select.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (FoodId, ReferenceMapId)
import Api.Types.FoodInfo exposing (FoodInfo)
import Api.Types.FoodStats exposing (FoodStats)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Food.Select.Status exposing (Status)
import Pages.Statistics.StatisticsUtil exposing (StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , foodInfo : FoodInfo
    , foodStats : FoodStats
    , statisticsEvaluation : StatisticsEvaluation
    , initialization : Initialization Status
    , variant : Page
    }


lenses :
    { foodInfo : Lens Model FoodInfo
    , foodStats : Lens Model FoodStats
    , statisticsEvaluation : Lens Model StatisticsEvaluation
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { foodInfo = Lens .foodInfo (\b a -> { a | foodInfo = b })
    , foodStats = Lens .foodStats (\b a -> { a | foodStats = b })
    , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , foodId : FoodId
    }


type Msg
    = GotFetchStatsResponse (Result Error FoodStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchFoodInfoResponse (Result Error FoodInfo)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
