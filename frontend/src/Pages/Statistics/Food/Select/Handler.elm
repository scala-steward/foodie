module Pages.Statistics.Food.Select.Handler exposing (init, update)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.FoodInfo exposing (FoodInfo)
import Api.Types.FoodStats exposing (FoodStats)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Monocle.Lens as Lens
import Pages.Statistics.Food.Select.Page as Page
import Pages.Statistics.Food.Select.Requests as Requests
import Pages.Statistics.StatisticsLenses as StatisticsLenses
import Pages.Statistics.StatisticsRequests as StatisticsRequests
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
        [ Requests.fetchFoodInfo flags
        , Requests.fetchStats flags
        , Requests.fetchReferenceTrees flags.authorizedAccess
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

        Page.GotFetchFoodInfoResponse result ->
            gotFetchFoodInfoResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error FoodStats -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\foodStats ->
                model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.foodStats.set
                            (foodStats
                                |> Lens.modify StatisticsLenses.foodStatsNutrients (List.sortBy (.base >> .name))
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


gotFetchFoodInfoResponse : Page.Model -> Result Error FoodInfo -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchFoodInfoResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\foodInfo ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.foodInfo.set (foodInfo |> Just))
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
