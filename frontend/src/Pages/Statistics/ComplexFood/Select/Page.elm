module Pages.Statistics.ComplexFood.Select.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (ComplexFoodId, ReferenceMapId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.ComplexFood.Select.Status exposing (Status)
import Pages.Statistics.StatisticsUtil exposing (StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , complexFood : ComplexFood
    , foodStats : TotalOnlyStats
    , statisticsEvaluation : StatisticsEvaluation
    , initialization : Initialization Status
    , variant : Page
    }


lenses :
    { complexFood : Lens Model ComplexFood
    , foodStats : Lens Model TotalOnlyStats
    , statisticsEvaluation : Lens Model StatisticsEvaluation
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { complexFood = Lens .complexFood (\b a -> { a | complexFood = b })
    , foodStats = Lens .foodStats (\b a -> { a | foodStats = b })
    , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , complexFoodId : ComplexFoodId
    }


type Msg
    = GotFetchStatsResponse (Result Error TotalOnlyStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchComplexFoodResponse (Result Error ComplexFood)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
