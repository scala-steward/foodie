module Pages.Statistics.Meal.Select.Handler exposing (init, update)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Meal exposing (Meal)
import Api.Types.Profile exposing (Profile)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens as Lens
import Pages.Statistics.Meal.Select.Page as Page
import Pages.Statistics.Meal.Select.Requests as Requests
import Pages.Statistics.StatisticsLenses as StatisticsLenses
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.HttpUtil exposing (Error)


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags |> Cmd.map Tristate.Logic
    )


initialFetch : Page.Flags -> Cmd Page.LogicMsg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchMeal flags.authorizedAccess flags.profileId flags.mealId
        , Requests.fetchStats flags.authorizedAccess flags.profileId flags.mealId
        , Requests.fetchReferenceTrees flags.authorizedAccess
        , Pages.Util.Requests.fetchProfileWith Page.GotFetchProfileResponse flags.authorizedAccess flags.profileId
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
    case msg of
        Page.GotFetchStatsResponse result ->
            gotFetchStatsResponse model result

        Page.GotFetchReferenceTreesResponse result ->
            gotFetchReferenceTreesResponse model result

        Page.GotFetchMealResponse result ->
            gotFetchMealResponse model result

        Page.GotFetchProfileResponse result ->
            gotFetchProfileResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error TotalOnlyStats -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
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


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith
        { referenceTreesLens = Page.lenses.initial.referenceTrees
        , initialToMain = Page.initialToMain
        }


gotFetchMealResponse : Page.Model -> Result Error Meal -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchMealResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\meal ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.meal.set (meal |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchProfileResponse : Page.Model -> Result Error Profile -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchProfileResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\profile ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.profile.set (profile |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


selectReferenceMap : Page.Model -> Maybe ReferenceMapId -> ( Page.Model, Cmd Page.LogicMsg )
selectReferenceMap =
    StatisticsRequests.selectReferenceMapWith
        { statisticsEvaluationLens = Page.lenses.main.statisticsEvaluation
        }


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setNutrientsSearchString =
    StatisticsRequests.setNutrientsSearchStringWith
        { statisticsEvaluationLens = Page.lenses.main.statisticsEvaluation
        }
