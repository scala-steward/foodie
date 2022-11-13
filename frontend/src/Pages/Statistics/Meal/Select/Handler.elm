module Pages.Statistics.Meal.Select.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Meal exposing (Meal)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.Meal.Select.Requests as Requests
import Pages.Statistics.Meal.Select.Status as Status
import Pages.Statistics.StatisticsLenses as StatisticsLenses
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Statistics.StatisticsUtil as StatisticsEvaluation
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , meal = Nothing
      , mealStats = { nutrients = [] }
      , statisticsEvaluation = StatisticsEvaluation.initial
      , initialization = Initialization.Loading Status.initial
      , variant = StatisticsVariant.Meal
      }
    , initialFetch flags
    )


initialFetch : Page.Flags -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchMeal flags
        , Requests.fetchStats flags
        , Requests.fetchReferenceTrees flags.authorizedAccess
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.GotFetchStatsResponse result ->
            gotFetchStatsResponse model result

        Page.GotFetchReferenceTreesResponse result ->
            gotFetchReferenceTreesResponse model result

        Page.GotFetchMealResponse result ->
            gotFetchMealResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error TotalOnlyStats -> ( Page.Model, Cmd Page.Msg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\mealStats ->
                model
                    |> (Page.lenses.mealStats |> Compose.lensWithLens StatisticsLenses.totalOnlyStatsNutrients).set (mealStats |> .nutrients |> List.sortBy (.base >> .name))
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.mealStats).set True
            )
    , Cmd.none
    )


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith
        { setError = setError
        , statisticsEvaluationLens = Page.lenses.statisticsEvaluation
        }


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotFetchMealResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\meal ->
                model
                    |> Page.lenses.meal.set (meal |> Just)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.meal).set True
            )
    , Cmd.none
    )


selectReferenceMap : Page.Model -> Maybe ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
selectReferenceMap =
    StatisticsRequests.selectReferenceMapWith
        { statisticsEvaluationLens = Page.lenses.statisticsEvaluation
        }


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setNutrientsSearchString =
    StatisticsRequests.setNutrientsSearchStringWith
        { statisticsEvaluationLens = Page.lenses.statisticsEvaluation
        }


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
