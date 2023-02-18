module Pages.Statistics.Recipe.Select.Handler exposing (init, update)

import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Recipe exposing (Recipe)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Monocle.Lens as Lens
import Pages.Statistics.Recipe.Select.Page as Page
import Pages.Statistics.Recipe.Select.Requests as Requests
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
        [ Requests.fetchRecipe flags
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

        Page.GotFetchRecipeResponse result ->
            gotFetchRecipeResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error TotalOnlyStats -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipeStats ->
                model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.recipeStats.set
                            (recipeStats
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


gotFetchRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchRecipeResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\recipe ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.recipe.set (recipe |> Just))
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
