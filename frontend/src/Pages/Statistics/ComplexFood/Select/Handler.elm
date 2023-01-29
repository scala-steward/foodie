module Pages.Statistics.ComplexFood.Select.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.ComplexFood exposing (ComplexFood)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Pages.Statistics.ComplexFood.Select.Page as Page
import Pages.Statistics.ComplexFood.Select.Requests as Requests
import Pages.Statistics.ComplexFood.Select.Status as Status
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
      , complexFood =
            { recipeId = flags.complexFoodId
            , name = ""
            , description = Nothing
            , amountGrams = 0
            , amountMilliLitres = Nothing
            }
      , foodStats = { nutrients = [] }
      , statisticsEvaluation = StatisticsEvaluation.initial
      , initialization = Initialization.Loading Status.initial
      , variant = StatisticsVariant.ComplexFood
      }
    , initialFetch flags
    )


initialFetch : Page.Flags -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchComplexFood flags
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

        Page.GotFetchComplexFoodResponse result ->
            gotFetchComplexFoodResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error TotalOnlyStats -> ( Page.Model, Cmd Page.Msg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFoodStats ->
                model
                    |> (Page.lenses.foodStats |> Compose.lensWithLens StatisticsLenses.totalOnlyStatsNutrients).set (complexFoodStats |> .nutrients |> List.sortBy (.base >> .name))
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFoodStats).set True
            )
    , Cmd.none
    )


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith
        { setError = setError
        , statisticsEvaluationLens = Page.lenses.statisticsEvaluation
        }


gotFetchComplexFoodResponse : Page.Model -> Result Error ComplexFood -> ( Page.Model, Cmd Page.Msg )
gotFetchComplexFoodResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\complexFood ->
                model
                    |> Page.lenses.complexFood.set complexFood
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.complexFood).set True
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
