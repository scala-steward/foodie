module Pages.Statistics.Recipe.Select.Handler exposing (init, update)

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ReferenceMapId)
import Api.Types.Recipe exposing (Recipe)
import Api.Types.ReferenceTree exposing (ReferenceTree)
import Api.Types.TotalOnlyStats exposing (TotalOnlyStats)
import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Pages.Statistics.Recipe.Select.Page as Page
import Pages.Statistics.Recipe.Select.Requests as Requests
import Pages.Statistics.Recipe.Select.Status as Status
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
      , recipe =
            { id = flags.recipeId
            , name = ""
            , description = Nothing
            , numberOfServings = 0
            }
      , recipeStats =
            { nutrients = []
            , weightInGrams = 0
            }
      , statisticsEvaluation = StatisticsEvaluation.initial
      , initialization = Initialization.Loading Status.initial
      , variant = StatisticsVariant.Recipe
      }
    , initialFetch flags
    )


initialFetch : Page.Flags -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchRecipe flags
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

        Page.GotFetchRecipeResponse result ->
            gotFetchRecipeResponse model result

        Page.SelectReferenceMap maybeReferenceMapId ->
            selectReferenceMap model maybeReferenceMapId

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string


gotFetchStatsResponse : Page.Model -> Result Error TotalOnlyStats -> ( Page.Model, Cmd Page.Msg )
gotFetchStatsResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\recipeStats ->
                model
                    |> (Page.lenses.recipeStats |> Compose.lensWithLens StatisticsLenses.totalOnlyStatsNutrients).set (recipeStats |> .nutrients |> List.sortBy (.base >> .name))
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipeStats).set True
            )
    , Cmd.none
    )


gotFetchReferenceTreesResponse : Page.Model -> Result Error (List ReferenceTree) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceTreesResponse =
    StatisticsRequests.gotFetchReferenceTreesResponseWith
        { setError = setError
        , statisticsEvaluationLens = Page.lenses.statisticsEvaluation
        }


gotFetchRecipeResponse : Page.Model -> Result Error Recipe -> ( Page.Model, Cmd Page.Msg )
gotFetchRecipeResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\recipe ->
                model
                    |> Page.lenses.recipe.set recipe
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.recipe).set True
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
