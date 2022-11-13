module Pages.Statistics.Food.Select.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.FoodInfo exposing (FoodInfo)
import Api.Types.FoodStats exposing (FoodStats)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Basics.Extra exposing (flip)
import Pages.Statistics.Food.Select.Page as Page
import Pages.Statistics.Food.Select.Requests as Requests
import Pages.Statistics.Food.Select.Status as Status
import Pages.Statistics.StatisticsRequests as StatisticsRequests
import Pages.Statistics.StatisticsUtil as StatisticsEvaluation
import Result.Extra
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , foodInfo =
            { id = flags.foodId
            , name = ""
            }
      , foodStats = { nutrients = [] }
      , statisticsEvaluation = StatisticsEvaluation.initial
      , initialization = Initialization.Loading Status.initial
      , variant = StatisticsVariant.Food
      }
    , initialFetch flags
    )


initialFetch : Page.Flags -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchFoodInfo flags
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

        Page.GotFetchFoodInfoResponse result ->
            gotFetchFoodInfoResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error FoodStats -> ( Page.Model, Cmd Page.Msg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\foodStats ->
                model
                    |> Page.lenses.foodStats.set foodStats
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.foodStats).set True
            )
    , Cmd.none
    )


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith
        { setError = setError
        , statisticsEvaluationLens = Page.lenses.statisticsEvaluation
        }


gotFetchFoodInfoResponse : Page.Model -> Result Error FoodInfo -> ( Page.Model, Cmd Page.Msg )
gotFetchFoodInfoResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\foodInfo ->
                model
                    |> Page.lenses.foodInfo.set foodInfo
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.foodInfo).set True
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
