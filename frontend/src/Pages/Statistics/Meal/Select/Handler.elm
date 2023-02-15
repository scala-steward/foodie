module Pages.Statistics.Meal.Select.Handler exposing (init, update)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Meal exposing (Meal)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens as Lens
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.Meal.Select.Requests as Requests
import Pages.Statistics.StatisticsLenses as StatisticsLenses
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
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
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\mealStats ->
                model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.mealStats.set
                            (mealStats
                                |> Lens.modify StatisticsLenses.totalOnlyStatsNutrients (List.sortBy (.base >> .name))
                                |> Just
                            )
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith2
        { referenceTreesLens = Page.lenses.initial.referenceTrees
        , initialToMain = Page.initialToMain
        }


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.Msg )
gotFetchMealResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\meal ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.meal.set (meal |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


selectReferenceMap : Page.Model -> Maybe ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
selectReferenceMap =
    StatisticsRequests.selectReferenceMapWith2
        { statisticsEvaluationLens = Page.lenses.main.statisticsEvaluation
        }


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setNutrientsSearchString =
    StatisticsRequests.setNutrientsSearchStringWith2
        { statisticsEvaluationLens = Page.lenses.main.statisticsEvaluation
        }
