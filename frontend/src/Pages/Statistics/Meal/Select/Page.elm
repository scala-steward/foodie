module Pages.Statistics.Meal.Select.Page exposing (..)

import Addresses.StatisticsVariant exposing (Page)
import Api.Auxiliary exposing (MealId, ReferenceMapId)
import Api.Types.Meal exposing (Meal)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens exposing (Lens)
import Pages.Statistics.Meal.Select.Status exposing (Status)
import Pages.Statistics.StatisticsUtil exposing (StatisticsEvaluation)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , meal : Maybe Meal
    , mealStats : TotalOnlyStats
    , statisticsEvaluation : StatisticsEvaluation
    , initialization : Initialization Status
    , variant : Page
    }


lenses :
    { meal : Lens Model (Maybe Meal)
    , mealStats : Lens Model TotalOnlyStats
    , statisticsEvaluation : Lens Model StatisticsEvaluation
    , initialization : Lens Model (Initialization Status)
    }
lenses =
    { meal = Lens .meal (\b a -> { a | meal = b })
    , mealStats = Lens .mealStats (\b a -> { a | mealStats = b })
    , statisticsEvaluation = Lens .statisticsEvaluation (\b a -> { a | statisticsEvaluation = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , mealId : MealId
    }


type Msg
    = GotFetchStatsResponse (Result Error TotalOnlyStats)
    | GotFetchReferenceTreesResponse (Result Error (List ReferenceTree))
    | GotFetchMealResponse (Result Error Meal)
    | SelectReferenceMap (Maybe ReferenceMapId)
    | SetNutrientsSearchString String
